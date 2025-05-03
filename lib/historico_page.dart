import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';
import 'package:pdf/pdf.dart';

class HistoricoPage extends StatefulWidget {
  @override
  _HistoricoPageState createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<Map<String, dynamic>> historico = [];
  List<int> selecionados = []; // IDs dos itens selecionados

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

  // 🔵 Função para gerar e compartilhar o PDF apenas dos registros selecionados
  Future<void> compartilharHistorico() async {
    final pdf = pw.Document();

    // Filtrando apenas os registros selecionados
    final historicoSelecionado = historico.where((item) => selecionados.contains(item['id'])).toList();

    if (historicoSelecionado.isEmpty) {
      // Se não houver nenhum registro selecionado, retornamos sem gerar o PDF
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
                    (item) {
                      final dataFormatada = item['data']; // Se necessário, formate aqui

                      return pw.TableRow(
                        children: [
                          pw.Text(dataFormatada),
                          pw.Text(item['ganhoKm'].toStringAsFixed(2)),
                          pw.Text(item['ganhoHora'].toStringAsFixed(2)),
                          pw.Text(item['ganhoMinuto'].toStringAsFixed(2)),
                          pw.Text(item['ganhoLiquido'].toStringAsFixed(2)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Compartilhar o PDF gerado
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
            onPressed: compartilharHistorico, // Chama a função de compartilhar
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: historico.length,
        itemBuilder: (context, index) {
          final item = historico[index];
          final isSelecionado = selecionados.contains(item['id']);

          return GestureDetector(
            onLongPress: () {
              setState(() {
                if (isSelecionado) {
                  selecionados.remove(item['id']);
                } else {
                  selecionados.add(item['id']);
                }
              });
            },
            onTap: () {
              if (selecionados.isNotEmpty) {
                setState(() {
                  if (isSelecionado) {
                    selecionados.remove(item['id']);
                  } else {
                    selecionados.add(item['id']);
                  }
                });
              }
            },
            child: Card(
              margin: EdgeInsets.all(8),
              color: isSelecionado ? Colors.blue.shade100 : null,
              child: ListTile(
                title: Text(item['data']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: getCorParaValor(item['ganhoKm'], 2.00, 1.70),
                      child: Text('Ganho por KM: R\$ ${item['ganhoKm'].toStringAsFixed(2)}'),
                    ),
                    Container(
                      color: getCorParaValor(item['ganhoHora'], 40.0, 35.0),
                      child: Text('Ganho por Hora: R\$ ${item['ganhoHora'].toStringAsFixed(2)}'),
                    ),
                    Container(
                      color: getCorParaValor(item['ganhoMinuto'], 1.0, 0.75),
                      child: Text('Ganho por Minuto: R\$ ${item['ganhoMinuto'].toStringAsFixed(2)}'),
                    ),
                    Container(
                      color: getCorParaValor(item['ganhoLiquido'], 200.0, 135.0),
                      child: Text('Ganho Líquido: R\$ ${item['ganhoLiquido'].toStringAsFixed(2)}'),
                    ),
                  ],
                ),
                trailing: selecionados.isEmpty
                    ? IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmarExclusao(context, [item['id']]);
                        },
                      )
                    : Icon(
                        isSelecionado ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelecionado ? Colors.blue : null,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
