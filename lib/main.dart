import 'package:flutter/material.dart';
import 'package:uberonv1beta/database_helper.dart';
import 'package:uberonv1beta/historico_page.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(UberON());
}

class UberON extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UberON',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController ganhoController = TextEditingController();
  final TextEditingController kmRodadosController = TextEditingController();
  final TextEditingController horasTrabalhadasController = TextEditingController();
  final TextEditingController custoController = TextEditingController();

  final FocusNode ganhoFocus = FocusNode();
  final FocusNode kmFocus = FocusNode();
  final FocusNode horasFocus = FocusNode();
  final FocusNode custoFocus = FocusNode();
  
  double ganhoPorMinuto = 0.0;
  double ganhoPorKm = 0.0;
  double ganhoPorHora = 0.0;
  double ganhoLiquido = 0.0;

  @override
  void initState() {
    super.initState();
    ganhoController.addListener(calcularResultados);
    kmRodadosController.addListener(calcularResultados);
    horasTrabalhadasController.addListener(calcularResultados);
    custoController.addListener(calcularResultados);
  }

  void calcularResultados() {
    final double ganho = double.tryParse(ganhoController.text) ?? 0.0;
    final double kmRodados = double.tryParse(kmRodadosController.text) ?? 0.0;
    final double horasTrabalhadas = double.tryParse(horasTrabalhadasController.text) ?? 0.0;
    final double custo = double.tryParse(custoController.text) ?? 0.0;

    setState(() {
      ganhoPorKm = kmRodados > 0 ? ganho / kmRodados : 0.0;
      ganhoPorHora = horasTrabalhadas > 0 ? ganho / horasTrabalhadas : 0.0;
      ganhoPorMinuto = horasTrabalhadas > 0 ? ganho / (horasTrabalhadas * 60) : 0.0;
      ganhoLiquido = ganho - custo;
    });

    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');

    final data = {
      'data': dateFormat.format(now),
      'ganhoKm': ganhoPorKm,
      'ganhoHora': ganhoPorHora,
      'ganhoMinuto': ganhoPorHora / 60,
      'ganhoLiquido': ganhoLiquido,
    };

    DatabaseHelper().inserirHistorico(data);
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
              _buildTextField(
                controller: ganhoController,
                label: 'Ganho (R\$)',
                focusNode: ganhoFocus,
              ),
              _buildTextField(
                controller: kmRodadosController,
                label: 'Km Rodados',
                focusNode: kmFocus,
              ),
              _buildTextField(
                controller: horasTrabalhadasController,
                label: 'Horas Trabalhadas',
                focusNode: horasFocus,
              ),
              _buildTextField(
                controller: custoController,
                label: 'Custo (R\$)',
                focusNode: custoFocus,
              ),
              const SizedBox(height: 24),
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

    // Cor padrão (sem dados) - azul claro
    if (valor == 0.0) {
      corFundo = Colors.blue.shade100;
      corTexto = Colors.blue;
    }
    // Ganho líquido
    else if (isLiquido) {
      corFundo = valor > 0 ? Colors.green.shade100 : Colors.red.shade100;
      corTexto = valor > 0 ? Colors.green : Colors.red;
    }
    // Outros resultados
    else {
      corFundo = Colors.grey.shade200;
      corTexto = Colors.black;
    }

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2, // divide em 2 colunas com padding
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