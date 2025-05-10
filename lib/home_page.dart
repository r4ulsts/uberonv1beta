import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uberonv1beta/database_helper.dart';
import 'package:uberonv1beta/historico_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController uberController = TextEditingController();
  final TextEditingController novenoveController = TextEditingController();
  final TextEditingController kmRodadosController = TextEditingController();
  final TextEditingController horasTrabalhadasController = TextEditingController();
  final TextEditingController custoController = TextEditingController();

  final FocusNode uberFocus = FocusNode();
  final FocusNode novenoveFocus = FocusNode();
  final FocusNode kmFocus = FocusNode();
  final FocusNode horasFocus = FocusNode();
  final FocusNode custoFocus = FocusNode();

  double ganhoPorMinuto = 0.0;
  double ganhoPorKm = 0.0;
  double ganhoPorHora = 0.0;
  double ganhoLiquido = 0.0;
  double porcentagemLucro = 0.0;
  double ganhoTotal = 0.0;

  Timer? _debounce; // Variável para debounce

 @override
void initState() {
  super.initState();
  uberController.addListener(_onInputChange);
  novenoveController.addListener(_onInputChange);
  kmRodadosController.addListener(_onInputChange);
  horasTrabalhadasController.addListener(_onInputChange);
  custoController.addListener(_onInputChange);
}

  @override
  void dispose() {
    _debounce?.cancel();
    uberController.dispose();
    novenoveController.dispose();
    kmRodadosController.dispose();
    horasTrabalhadasController.dispose();
    custoController.dispose();
    uberFocus.dispose();
    novenoveFocus.dispose();
    kmFocus.dispose();
    horasFocus.dispose();
    custoFocus.dispose();
    super.dispose();
  }
void _onInputChange() {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    calcularResultados();
  });
}

void _resetarDados() {
  Timer? autoResetTimer; // Declaração correta no escopo adequado

  showDialog(
    context: context,
    builder: (context) {
      int segundosRestantes = 5;

      return StatefulBuilder(
        builder: (context, setState) {
          // Inicializa o timer para atualização do botão
          autoResetTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
            if (segundosRestantes > 1) {
              if (!Navigator.of(context).canPop()) {
                timer.cancel(); // Cancela o timer se o diálogo for fechado
              } else {
                setState(() => segundosRestantes--); // Atualiza o botão apenas se estiver montado
              }
            } else {
              timer.cancel();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); // Fecha o diálogo antes de resetar os dados
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
                  autoResetTimer?.cancel(); // Cancela o timer para evitar erro
                  Navigator.of(context).pop(); // Fecha o diálogo sem limpar os dados
                },
                child: Text("Cancelar"),
              ),
              TextButton(
                onPressed: () {
                  autoResetTimer?.cancel(); // Cancela o timer para evitar reset automático
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
    // Garante que o timer seja cancelado ao fechar o diálogo de qualquer forma
    autoResetTimer?.cancel();
  });
}

/// Método para limpar os campos do formulário
void _limparCampos() {
  uberController.clear();
  novenoveController.clear();
  kmRodadosController.clear();
  horasTrabalhadasController.clear();
  custoController.clear();
}

  void calcularResultados() {
    final double uber = _parseToDouble(uberController.text);
    final double novenove = _parseToDouble(novenoveController.text);
    final double kmRodados = _parseToDouble(kmRodadosController.text);
    final double horasTrabalhadas = _parseToDouble(horasTrabalhadasController.text);
    final double custo = _parseToDouble(custoController.text);

    final double ganho = uber + novenove;

    setState(() {
      ganhoTotal = ganho;
      ganhoPorKm = kmRodados > 0 ? ganho / kmRodados : 0.0;
      ganhoPorHora = horasTrabalhadas > 0 ? ganho / horasTrabalhadas : 0.0;
      ganhoPorMinuto = horasTrabalhadas > 0 ? ganho / (horasTrabalhadas * 60) : 0.0;
      ganhoLiquido = ganho - custo;
      porcentagemLucro = ganho > 0 ? (ganhoLiquido / ganho) * 100 : 0.0;
    });
  }

  double _parseToDouble(String value) {
    value = value.replaceAll(',', '.');
    return double.tryParse(value) ?? 0.0;
  }

  void _salvarHistorico() {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final uber = _parseToDouble(uberController.text);
    final novenove = _parseToDouble(novenoveController.text);
    final kmRodados = _parseToDouble(kmRodadosController.text);
    final horasTrabalhadas = _parseToDouble(horasTrabalhadasController.text);
    final custo = _parseToDouble(custoController.text);

    final ganho = uber + novenove;

    final data = {
      'data': dateFormat.format(now),
      'valorUber': uber,
      'valor99': novenove,
      'kmRodados': kmRodados,
      'horasTrabalhadas': horasTrabalhadas,
      'custo': custo,
      'ganho': ganho,
      'ganhoKm': kmRodados > 0 ? ganho / kmRodados : 0.0,
      'ganhoHora': horasTrabalhadas > 0 ? ganho / horasTrabalhadas : 0.0,
      'ganhoMinuto': horasTrabalhadas > 0 ? ganho / (horasTrabalhadas * 60) : 0.0,
      'ganhoLiquido': ganho - custo,
    };

    DatabaseHelper().inserirHistorico(data);

    uberController.clear();
    novenoveController.clear();
    kmRodadosController.clear();
    horasTrabalhadasController.clear();
    custoController.clear();

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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: uberController, label: 'Uber (R\$)', focusNode: uberFocus)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller: novenoveController, label: '99 (R\$)', focusNode: novenoveFocus)),
                ],
              ),
              // Card para exibir o Ganho Total
              Card(
                color: Colors.blue.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  child: Center(
                    child: Text(
                      'Ganho Total: R\$ ${ganhoTotal.toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: kmRodadosController, label: 'Km Rodados', focusNode: kmFocus)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller: horasTrabalhadasController, label: 'Horas Trabalhadas', focusNode: horasFocus)),
                ],
              ),
              const SizedBox(height: 1),
              _buildTextField(controller: custoController, label: 'Custo (R\$)', focusNode: custoFocus),
              const SizedBox(height: 1),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildResultadoCard('Ganho por Minuto', ganhoPorMinuto),
                  _buildResultadoCard('Ganho por Km', ganhoPorKm),
                  _buildResultadoCard('Ganho por Hora', ganhoPorHora),
                  _buildResultadoCard('Ganho Líquido', ganhoLiquido, isLiquido: true),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _salvarHistorico,
                icon: Icon(Icons.save),
                label: Text('Salvar no Histórico'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8), // Espaço entre os botões
              ElevatedButton.icon(
                onPressed: _resetarDados,
                icon: Icon(Icons.refresh),
                label: Text("Resetar Dados"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                  backgroundColor: const Color.fromARGB(255, 247, 223, 10), // Cor para destacar o reset
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
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'R\$ ${valor.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: corTexto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}