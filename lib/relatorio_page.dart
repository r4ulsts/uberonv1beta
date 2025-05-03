import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class RelatorioPage extends StatefulWidget {
  @override
  _RelatorioPageState createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  List<Map<String, dynamic>> historico = [];

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  Future<void> carregarHistorico() async {
    // Remove a filtragem por data e carrega todos os registros
    List<Map<String, dynamic>> todosRegistros = await DatabaseHelper().listarHistorico();
    setState(() {
      historico = todosRegistros;  // Exibe todos os dados
    });
  }

  @override
  Widget build(BuildContext context) {
    double ganhoTotal = historico.fold(0.0, (sum, item) => sum + item['ganhoLiquido']);
    double distanciaTotal = historico.fold(0.0, (sum, item) => sum + (item['distancia'] ?? 0.0));
    double ganhoKm = distanciaTotal > 0 ? ganhoTotal / distanciaTotal : 0;
    double ganhoHora = historico.fold(0.0, (sum, item) => sum + (item['ganhoHora'] ?? 0.0)) / (historico.isNotEmpty ? historico.length : 1);
    double ganhoMinuto = ganhoHora / 60;

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: historico.isEmpty
            ? Center(child: Text('Nenhum dado encontrado.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: ganhoTotal > 0 ? ganhoTotal * 1.2 : 100,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toStringAsFixed(0));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Km');
                                  case 1:
                                    return Text('Hora');
                                  case 2:
                                    return Text('Min');
                                  case 3:
                                    return Text('Total');
                                  default:
                                    return Text('');
                                }
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: ganhoKm,
                                color: Colors.blueAccent,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: ganhoHora,
                                color: Colors.green,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: ganhoMinuto,
                                color: Colors.orange,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: ganhoTotal,
                                color: Colors.purple,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Resumo: ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Total ganho líquido: R\$ ${ganhoTotal.toStringAsFixed(2)}'),
                  Text('Total rodado: ${distanciaTotal.toStringAsFixed(2)} km'),
                  Text('Ganho médio por km: R\$ ${ganhoKm.toStringAsFixed(2)}'),
                  Text('Ganho médio por hora: R\$ ${ganhoHora.toStringAsFixed(2)}'),
                  Text('Ganho médio por minuto: R\$ ${ganhoMinuto.toStringAsFixed(2)}'),
                ],
              ),
      ),
    );
  }
}