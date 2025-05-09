import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uberonv1beta/database_helper.dart';
import 'package:uberonv1beta/historico_page.dart';

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

  @override
  void initState() {
    super.initState();
    uberController.addListener(calcularResultados);
    novenoveController.addListener(calcularResultados);
    kmRodadosController.addListener(calcularResultados);
    horasTrabalhadasController.addListener(calcularResultados);
    custoController.addListener(calcularResultados);
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
              const SizedBox(height: 1),
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _salvarHistorico,
                icon: Icon(Icons.save),
                label: Text('Salvar no Histórico'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
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