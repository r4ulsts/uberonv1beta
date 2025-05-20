import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uberonv1beta/database_helper.dart';
import 'package:uberonv1beta/historico_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Campos de valor Uber e 99
  final TextEditingController uberController = TextEditingController();
  final TextEditingController novenoveController = TextEditingController();
  // Campos para Km Rodados e Horas Trabalhadas
  final TextEditingController kmRodadosController = TextEditingController();
  final TextEditingController horasTrabalhadasController = TextEditingController();
  // Novos campos: Último Abastecimento e Média Atual do carro
  final TextEditingController abastecimentoController = TextEditingController();
  final TextEditingController mediaCarroController = TextEditingController();

  // FocusNodes
  final FocusNode uberFocus = FocusNode();
  final FocusNode novenoveFocus = FocusNode();
  final FocusNode kmFocus = FocusNode();
  final FocusNode horasFocus = FocusNode();
  final FocusNode abastecimentoFocus = FocusNode();
  final FocusNode mediaFocus = FocusNode();

  // Variáveis de cálculo dos resultados
  double ganhoPorMinuto = 0.0;
  double ganhoPorKm = 0.0;
  double ganhoPorHora = 0.0;
  double ganhoLiquido = 0.0;
  double porcentagemLucro = 0.0;
  double ganhoTotal = 0.0;
  
  // Novas variáveis para o custo calculado
  double custoTotal = 0.0;
  double litrosGastosTotal = 0.0;

    // Variáveis para armazenar os últimos valores inseridos
  String? lastUber;
  String? lastNovenove;
  String? lastKmRodados;
  String? lastHorasTrabalhadas;


  Timer? _debounce; // Variável para debounce

  @override
  void initState() {
    super.initState();
    uberController.addListener(_onInputChange);
    novenoveController.addListener(_onInputChange);
    kmRodadosController.addListener(_onInputChange);
    horasTrabalhadasController.addListener(_onInputChange);
    abastecimentoController.addListener(_onInputChange);
    mediaCarroController.addListener(_onInputChange);
    _loadLastValues(); // Agora carregamos os valores ao iniciar a tela

    Future<void> _cacheNewFieldValue(String key, String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

    // Cache dos novos campos
    abastecimentoController.addListener(() {
      _cacheNewFieldValue("abastecimento", abastecimentoController.text);
    });
    mediaCarroController.addListener(() {
      _cacheNewFieldValue("mediaCarro", mediaCarroController.text);
    });
    _loadCachedValues();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    uberController.dispose();
    novenoveController.dispose();
    kmRodadosController.dispose();
    horasTrabalhadasController.dispose();
    abastecimentoController.dispose();
    mediaCarroController.dispose();
    uberFocus.dispose();
    novenoveFocus.dispose();
    kmFocus.dispose();
    horasFocus.dispose();
    abastecimentoFocus.dispose();
    mediaFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCachedValues() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? abastecimentoValue = prefs.getString("abastecimento");
    final String? mediaCarroValue = prefs.getString("mediaCarro");
    if (abastecimentoValue != null) {
      abastecimentoController.text = abastecimentoValue;
    }
    if (mediaCarroValue != null) {
      mediaCarroController.text = mediaCarroValue;
    }
  }
    Future<void> _loadLastValues() async {
      final prefs = await SharedPreferences.getInstance();

      final String? savedUber = prefs.getString('lastUber');
      final String? savedNovenove = prefs.getString('lastNovenove');

      setState(() {
        lastUber = savedUber != null && !savedUber.startsWith('Último: R\$') 
            ? 'Último: R\$${savedUber}' 
            : savedUber ?? 'Digite o valor da Uber';

        lastNovenove = savedNovenove != null && !savedNovenove.startsWith('Último: R\$') 
            ? 'Último: R\$${savedNovenove}' 
            : savedNovenove ?? 'Digite o valor do 99';

        lastKmRodados = prefs.getString('lastKmRodados') ?? 'Digite o Km rodado';
        lastHorasTrabalhadas = prefs.getString('lastHorasTrabalhadas') ?? 'Digite as horas trabalhadas';
      });
    }

  void _onInputChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      calcularResultados();
    });
  }

  void _resetarDados() {
    Timer? autoResetTimer;
    showDialog(
      context: context,
      builder: (context) {
        int segundosRestantes = 5;
        return StatefulBuilder(
          builder: (context, setState) {
            autoResetTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (segundosRestantes > 1) {
                if (!Navigator.of(context).canPop()) {
                  timer.cancel();
                } else {
                  setState(() => segundosRestantes--);
                }
              } else {
                timer.cancel();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                _limparCampos();
              }
            });
            return AlertDialog(
              title: Text("Confirmar Reset"),
              content: Text("Tem certeza que deseja apagar os dados preenchidos?"),
              actions: [
                TextButton(
                  onPressed: () {
                    autoResetTimer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    autoResetTimer?.cancel();
                    Navigator.of(context).pop();
                    _limparCampos();
                  },
                  child: Text("Sim ($segundosRestantes)"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      autoResetTimer?.cancel();
    });
  }

  // Nota: Agora não limpamos os campos de abastecimento e média do carro
  void _limparCampos() {
    uberController.clear();
    novenoveController.clear();
    kmRodadosController.clear();
    horasTrabalhadasController.clear();
  }

  void calcularResultados() {
    final double uber = _parseToDouble(uberController.text);
    final double novenove = _parseToDouble(novenoveController.text);
    final double kmRodados = _parseToDouble(kmRodadosController.text);
    final double horasTrabalhadas = _parseToDouble(horasTrabalhadasController.text);
    final double valorAbastecimento = _parseToDouble(abastecimentoController.text);
    final double mediaAtual = _parseToDouble(mediaCarroController.text);

    final double ganho = uber + novenove;
    double litrosGastos = 0.0;
    double custoCalculado = 0.0;
    if (mediaAtual > 0) {
      litrosGastos = kmRodados / mediaAtual;
      custoCalculado = litrosGastos * valorAbastecimento;
    }
    setState(() {
      ganhoTotal = ganho;
      ganhoPorKm = kmRodados > 0 ? ganho / kmRodados : 0.0;
      ganhoPorHora = horasTrabalhadas > 0 ? ganho / horasTrabalhadas : 0.0;
      ganhoPorMinuto = horasTrabalhadas > 0 ? ganho / (horasTrabalhadas * 60) : 0.0;
      custoTotal = custoCalculado;
      litrosGastosTotal = litrosGastos;
      ganhoLiquido = ganho - custoCalculado;
      porcentagemLucro = ganho > 0 ? (ganhoLiquido / ganho) * 100 : 0.0;
    });
  }

  double _parseToDouble(String value) {
    value = value.replaceAll(',', '.');
    return double.tryParse(value) ?? 0.0;
  }
void _salvarHistorico() async {
  final now = DateTime.now();
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final prefs = await SharedPreferences.getInstance();

  final double uber = _parseToDouble(uberController.text);
  final double novenove = _parseToDouble(novenoveController.text);
  final double kmRodados = _parseToDouble(kmRodadosController.text);
  final double horasTrabalhadas = _parseToDouble(horasTrabalhadasController.text);
  final double valorAbastecimento = _parseToDouble(abastecimentoController.text);
  final double mediaAtual = _parseToDouble(mediaCarroController.text);

  double litrosGastos = 0.0;
  double custoCalculado = 0.0;

  if (mediaAtual > 0) {
    litrosGastos = kmRodados / mediaAtual;
    custoCalculado = litrosGastos * valorAbastecimento;
  }

  final double ganho = uber + novenove;

  final data = {
    'data': dateFormat.format(now),
    'valorUber': uber,
    'valor99': novenove,
    'kmRodados': kmRodados,
    'horasTrabalhadas': horasTrabalhadas,
    'custo': custoCalculado,
    'ganho': ganho,
    'ganhoKm': kmRodados > 0 ? ganho / kmRodados : 0.0,
    'ganhoHora': horasTrabalhadas > 0 ? ganho / horasTrabalhadas : 0.0,
    'ganhoMinuto': horasTrabalhadas > 0 ? ganho / (horasTrabalhadas * 60) : 0.0,
    'ganhoLiquido': ganho - custoCalculado,
  };

  DatabaseHelper().inserirHistorico(data);

  // **Salvar os últimos valores inseridos nos campos Uber, 99, Km Rodados e Horas Trabalhadas**
  final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  await prefs.setString('lastUber', 'Último: ${formatador.format(uber)}');
  await prefs.setString('lastNovenove', 'Último: ${formatador.format(novenove)}');
  await prefs.setString('lastKmRodados', kmRodadosController.text);
  await prefs.setString('lastHorasTrabalhadas', horasTrabalhadasController.text);

  // **Atualizar os placeholders dos campos com os últimos valores**
  setState(() {
    lastUber = uberController.text;
    lastNovenove = novenoveController.text;
    lastKmRodados = kmRodadosController.text;
    lastHorasTrabalhadas = horasTrabalhadasController.text;
  });

  // **Limpar os campos de entrada**
  uberController.clear();
  novenoveController.clear();
  kmRodadosController.clear();
  horasTrabalhadasController.clear();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Dados salvos no histórico!')),
  );
}
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('UberON', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoricoPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Reduzi a margem geral
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha para Uber e 99
              // Linha para Uber e 99 (permanece inalterada)
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: uberController,
                      label: 'Uber (R\$)',
                      focusNode: uberFocus,
                      hintText: lastUber ?? 'Digite o valor da Uber', // Agora usando o último valor salvo!
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: novenoveController,
                      label: '99 (R\$)',
                      focusNode: novenoveFocus,
                      hintText: lastNovenove ?? 'Digite o valor do 99', // Recuperando último valor salvo!
                    ),
                  ),
                ],
              ),

              // Card para exibir o Ganho Total
              Card(
                color: Colors.blue.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: Center(
                    child: Text(
                      'Ganho Total: R\$ ${ganhoTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12), // Espaço aumentado abaixo do card de Ganho Total
              // Linha para Km Rodados e Horas Trabalhadas
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: kmRodadosController, label: 'Km Rodados', focusNode: kmFocus)),
                  SizedBox(width: 16), // Espaçamento aumentado de 8 para 16
                  Expanded(child: _buildTextField(controller: horasTrabalhadasController, label: 'Horas Trabalhadas', focusNode: horasFocus)),
                ],
              ),
              const SizedBox(height: 8),
              // Linha para os novos campos: Último Abastecimento e Média Atual
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: abastecimentoController, label: 'Último Abastecimento (R\$)', focusNode: abastecimentoFocus)),
                  SizedBox(width: 16), // Espaçamento aumentado aqui também
                  Expanded(child: _buildTextField(controller: mediaCarroController, label: 'Média Atual (Km/L)', focusNode: mediaFocus)),
                ],
              ),
              const SizedBox(height: 2),
              // Wrap para os cards dos resultados com centralização
              Wrap(
                alignment: WrapAlignment.center,  // Centraliza horizontalmente
                runAlignment: WrapAlignment.center, // Centraliza as linhas
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildResultadoCard('Ganho por Minuto', ganhoPorMinuto),
                  _buildResultadoCard('Ganho por Km', ganhoPorKm),
                  _buildResultadoCard('Ganho por Hora', ganhoPorHora),
                  _buildResultadoCard('Ganho Líquido', ganhoLiquido, isLiquido: true),
                ],
              ),
              const SizedBox(height: 4),
              // Card para exibir o custo calculado e os litros gastos (altura reduzida)
              Card(
                color: Colors.orange.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Custo: R\$ ${custoTotal.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${litrosGastosTotal.toStringAsFixed(2)} Litros)',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: _salvarHistorico,
                icon: Icon(Icons.save),
                label: Text('Salvar no Histórico'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: _resetarDados,
                icon: Icon(Icons.refresh),
                label: Text("Resetar Dados"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                  backgroundColor: Color.fromARGB(255, 247, 223, 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    String? hintText, // Adicionando o parâmetro opcional
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText, // Agora passamos a dica corretamente
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildResultadoCard(String titulo, double valor, {bool isLiquido = false}) {
    Color corFundo;
    Color corTexto;
    if (valor == 0.0) {
      corFundo = Colors.blue.shade100;
      corTexto = Colors.blue;
    } else {
      switch (titulo) {
        case 'Ganho por Km':
          if (valor >= 2.00) {
            corFundo = Colors.green.shade100;
            corTexto = Colors.green;
          } else if (valor >= 1.70) {
            corFundo = Colors.yellow.shade100;
            corTexto = Colors.orange;
          } else {
            corFundo = Colors.red.shade100;
            corTexto = Colors.red;
          }
          break;
        case 'Ganho por Hora':
          if (valor >= 40.00) {
            corFundo = Colors.green.shade100;
            corTexto = Colors.green;
          } else if (valor >= 35.00) {
            corFundo = Colors.yellow.shade100;
            corTexto = Colors.orange;
          } else {
            corFundo = Colors.red.shade100;
            corTexto = Colors.red;
          }
          break;
        case 'Ganho por Minuto':
          if (valor >= 1.00) {
            corFundo = Colors.green.shade100;
            corTexto = Colors.green;
          } else if (valor >= 0.75) {
            corFundo = Colors.yellow.shade100;
            corTexto = Colors.orange;
          } else {
            corFundo = Colors.red.shade100;
            corTexto = Colors.red;
          }
          break;
        case 'Ganho Líquido':
          if (porcentagemLucro > 70) {
            corFundo = Colors.green.shade100;
            corTexto = Colors.green;
          } else if (porcentagemLucro >= 65) {
            corFundo = Colors.yellow.shade100;
            corTexto = Colors.orange;
          } else {
            corFundo = Colors.red.shade100;
            corTexto = Colors.red;
          }
          break;
        default:
          corFundo = Colors.grey.shade200;
          corTexto = Colors.black;
      }
    }
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: corFundo,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'R\$ ${valor.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: corTexto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}