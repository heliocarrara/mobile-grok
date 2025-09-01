import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/atividade_provider.dart';
import '../models/atividade.dart';
import '../utils/theme.dart';
import '../services/database_service.dart';

class CicloSonoScreen extends StatefulWidget {
  const CicloSonoScreen({super.key});

  @override
  State<CicloSonoScreen> createState() => _CicloSonoScreenState();
}

class _CicloSonoScreenState extends State<CicloSonoScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Map<int, TimeOfDay> _horariosSono = {};
  bool _isLoading = true;

  final List<String> _diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadHorariosSono();
  }

  Future<void> _loadHorariosSono() async {
    try {
      for (int i = 0; i < 7; i++) {
        final horarioStr = await _databaseService.getConfiguracao('sono_dia_$i');
        if (horarioStr != null) {
          final parts = horarioStr.split(':');
          if (parts.length == 2) {
            _horariosSono[i] = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarHorario(int dia, TimeOfDay horario) async {
    try {
      await _databaseService.setConfiguracao(
        'sono_dia_$dia',
        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
      );
      setState(() {
        _horariosSono[dia] = horario;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar horário')),
        );
      }
    }
  }

  Future<void> _criarAtividadesSono() async {
    try {
      final provider = context.read<AtividadeProvider>();
      final now = DateTime.now();
      
      for (int i = 0; i < 7; i++) {
        final horario = _horariosSono[i];
        if (horario != null) {
          // Calculate the date for this day of the week
          final diasParaAdicionar = (i + 1) - now.weekday;
          final dataAtividade = now.add(Duration(days: diasParaAdicionar));
          
          final dataHoraSono = DateTime(
            dataAtividade.year,
            dataAtividade.month,
            dataAtividade.day,
            horario.hour,
            horario.minute,
          );

          // Check if sleep activity already exists for this day
          final atividadesExistentes = await provider.getAtividadesByDate(dataAtividade);
          final jaExiste = atividadesExistentes.any((a) => 
            a.titulo.toLowerCase().contains('sono') && 
            a.dataHora.hour == horario.hour && 
            a.dataHora.minute == horario.minute
          );

          if (!jaExiste) {
            final atividade = Atividade(
              titulo: 'Sono',
              descricao: 'Horário de dormir - ${_diasSemana[i]}',
              categoria: CategoriaEnum.saude,
              dataHora: dataHoraSono,
              duracao: 480, // 8 hours
              prioridade: 3,
              repeticao: RepeticaoEnum.semanal,
            );

            await provider.addAtividade(atividade);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atividades de sono criadas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar atividades de sono')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciclo de Sono'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure seus horários de sono',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Defina o horário de dormir para cada dia da semana',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final horario = _horariosSono[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.bedtime,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            _diasSemana[index],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            horario != null
                                ? 'Dormir às ${horario.format(context)}'
                                : 'Horário não definido',
                            style: TextStyle(
                              color: horario != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () async {
                              final novoHorario = await showTimePicker(
                                context: context,
                                initialTime: horario ?? const TimeOfDay(hour: 22, minute: 0),
                              );
                              if (novoHorario != null) {
                                await _salvarHorario(index, novoHorario);
                              }
                            },
                            icon: Icon(
                              horario != null ? Icons.edit : Icons.add,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _horariosSono.isNotEmpty ? _criarAtividadesSono : null,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Criar Atividades de Sono'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
