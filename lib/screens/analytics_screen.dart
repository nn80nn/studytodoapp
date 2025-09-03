import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_bloc.dart';
import '../blocs/subjects_bloc.dart';
import '../models/task.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TasksBloc>().add(RefreshTasks());
              context.read<SubjectsBloc>().add(RefreshSubjects());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<TasksBloc>().add(RefreshTasks());
          context.read<SubjectsBloc>().add(RefreshSubjects());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<TasksBloc, TasksState>(
                builder: (context, state) {
                  if (state is TasksLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TasksLoaded) {
                    return _buildTasksStats(state.tasks);
                  } else if (state is TasksError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Ошибка загрузки задач: ${state.message}'),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              const SizedBox(height: 20),
              BlocBuilder<SubjectsBloc, SubjectsState>(
                builder: (context, state) {
                  if (state is SubjectsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SubjectsLoaded) {
                    return _buildSubjectsStats(state.subjects.length);
                  } else if (state is SubjectsError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Ошибка загрузки предметов: ${state.message}'),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksStats(List<Task> tasks) {
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).length;
    final pendingTasks = tasks.where((task) => task.status == TaskStatus.pending).length;
    final overdueTasks = tasks.where((task) => 
        task.status == TaskStatus.overdue || 
        (task.status == TaskStatus.pending && task.deadline.isBefore(DateTime.now()))
    ).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика задач',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Всего задач', tasks.length, Colors.blue),
            _buildStatRow('Выполнено', completedTasks, Colors.green),
            _buildStatRow('В работе', pendingTasks, Colors.orange),
            _buildStatRow('Просрочено', overdueTasks, Colors.red),
            const SizedBox(height: 16),
            if (tasks.isNotEmpty) ...[
              Text('Процент выполнения: ${(completedTasks / tasks.length * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completedTasks / tasks.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsStats(int subjectsCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика предметов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Всего предметов', subjectsCount, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}