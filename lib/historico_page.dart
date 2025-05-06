import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';
import 'package:pdf/pdf.dart';

class HistoricoPage extends StatefulWidget {
  @override
  _HistoricoPageDevState createState() => _HistoricoPageDevState();
}

class _HistoricoPageDevState extends State<HistoricoPage> {
  List<Map<String, dynamic>> historico = [];
  List<int> selecionados = [];

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    historico = await DatabaseHelper().listarHistorico();
    setState(() {});
  }

  Future<void> _atualizarLista() async {
    historico = await DatabaseHelper().listarHistorico();
    selecionados.clear();
    setState(() {});
  }

  void _confirmarExclusao(BuildContext context, List<int> ids) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir ${ids.length} registro(s)?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                for (var id in ids) {
                  await DatabaseHelper().deletarHistorico(id);
                }
                Navigator.of(context).pop();
                _atualizarLista();
              },
            ),
          ],
        );
      },
    );
  }

  Color getCorParaValor(double valor, double bom, double medio) {
    if (valor >= bom) {
      return Colors.green.shade200;
    } else if (valor >= medio) {
      return Colors.yellow.shade200;
    } else {
      return Colors.red.shade200;
    }
  }

  String formatarValor(dynamic valor) {
    if (valor is num) return valor.toStringAsFixed(2);
    return '0.00';
  }

  void alternarSelecao(int id) {
    setState(() {
      if (selecionados.contains(id)) {
        selecionados.remove(id);
      } else {
        selecionados.add(id);
      }
    });
  }

  Future<void> compartilharHistorico() async {
    final pdf = pw.Document();
    final historicoSelecionado = historico.where((item) => selecionados.contains(item['id'])).toList();

    if (historicoSelecionado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum registro selecionado para compartilhar')),
      );
      return;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Histórico de Ganhos', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ganho por KM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ganho por Hora', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ganho por Minuto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ganho Líquido', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...historicoSelecionado.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Text(item['data']),
                        pw.Text(formatarValor(item['ganhoKm'])),
                        pw.Text(formatarValor(item['ganhoHora'])),
                        pw.Text(formatarValor(item['ganhoMinuto'])),
                        pw.Text(formatarValor(item['ganhoLiquido'])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'historico_selecionado.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selecionados.isEmpty
            ? Text('Histórico')
            : Text('${selecionados.length} selecionado(s)'),
        actions: [
          if (selecionados.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _confirmarExclusao(context, selecionados),
            ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: compartilharHistorico,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: historico.length,
        itemBuilder: (context, index) {
          final item = historico[index];
          final isSelecionado = selecionados.contains(item['id']);

          return GestureDetector(
            onLongPress: () => alternarSelecao(item['id']),
            onTap: () {
              if (selecionados.isNotEmpty) {
                alternarSelecao(item['id']);
              }
            },
            child: Card(
              margin: EdgeInsets.all(8),
              color: isSelecionado ? Colors.blue.shade100 : null,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['data'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'R\$ ${formatarValor(item['ganho'])}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      color: getCorParaValor(item['ganhoKm'], 2.00, 1.70),
                      width: double.infinity,
                      padding: EdgeInsets.all(4),
                      child: Text('Ganho por KM: R\$ ${formatarValor(item['ganhoKm'])}'),
                    ),
                    Container(
                      color: getCorParaValor(item['ganhoHora'], 40.0, 35.0),
                      width: double.infinity,
                      padding: EdgeInsets.all(4),
                      child: Text('Ganho por Hora: R\$ ${formatarValor(item['ganhoHora'])}'),
                    ),
                    Container(
                      color: getCorParaValor(item['ganhoMinuto'], 1.0, 0.75),
                      width: double.infinity,
                      padding: EdgeInsets.all(4),
                      child: Text('Ganho por Minuto: R\$ ${formatarValor(item['ganhoMinuto'])}'),
                    ),
                    Container(
                      color: getCorParaValor(item['ganhoLiquido'], 200.0, 135.0),
                      width: double.infinity,
                      padding: EdgeInsets.all(4),
                      child: Text('Ganho Líquido: R\$ ${formatarValor(item['ganhoLiquido'])}'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}