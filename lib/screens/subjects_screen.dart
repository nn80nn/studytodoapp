import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/subjects_bloc.dart';
import '../models/subject.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предметы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SubjectsBloc>().add(RefreshSubjects()),
          ),
        ],
      ),
      body: BlocBuilder<SubjectsBloc, SubjectsState>(
        builder: (context, state) {
          if (state is SubjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SubjectsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SubjectsBloc>().add(RefreshSubjects());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: state.subjects.isEmpty
                  ? const Center(
                      child: Text('Пока нет предметов. Добавьте первый!'),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.subjects.length,
                      itemBuilder: (context, index) {
                        final subject = state.subjects[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: subject.color,
                              child: Text(
                                subject.name.isNotEmpty ? subject.name[0] : 'S',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(subject.name),
                            subtitle: subject.description != null 
                                ? Text(subject.description!) 
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditSubjectDialog(context, subject),
                                  tooltip: 'Редактировать',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSubject(context, subject),
                                  tooltip: 'Удалить',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            );
          } else if (state is SubjectsError) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SubjectsBloc>().add(RefreshSubjects());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Center(child: Text('Ошибка: ${state.message}')),
            );
          } else if (state is SubjectAdding || state is SubjectDeleting || state is SubjectUpdating) {
            return Stack(
              children: [
                BlocBuilder<SubjectsBloc, SubjectsState>(
                  buildWhen: (previous, current) => current is SubjectsLoaded,
                  builder: (context, previousState) {
                    if (previousState is SubjectsLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<SubjectsBloc>().add(RefreshSubjects());
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        child: previousState.subjects.isEmpty
                            ? const Center(
                                child: Text('Пока нет предметов. Добавьте первый!'),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: previousState.subjects.length,
                                itemBuilder: (context, index) {
                                  final subject = previousState.subjects[index];
                                  return Card(
                                    margin: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: subject.color,
                                        child: Text(
                                          subject.name.isNotEmpty ? subject.name[0] : 'S',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(subject.name),
                                      subtitle: subject.description != null 
                                          ? Text(subject.description!) 
                                          : null,
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteSubject(context, subject),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Загрузка...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEditSubjectDialog(),
    );
  }

  void _showEditSubjectDialog(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => _AddEditSubjectDialog(subject: subject),
    );
  }

  void _deleteSubject(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить предмет?'),
        content: Text('Вы уверены, что хотите удалить предмет "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<SubjectsBloc>().add(DeleteSubject(subject.id));
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _AddEditSubjectDialog extends StatefulWidget {
  final Subject? subject;
  
  const _AddEditSubjectDialog({Key? key, this.subject}) : super(key: key);

  @override
  _AddEditSubjectDialogState createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<_AddEditSubjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _descriptionController.text = widget.subject!.description ?? '';
      _selectedColor = widget.subject!.color;
    } else {
      _selectedColor = const Color(0xFF26C6DA);
    }
  }

  final List<Color> _availableColors = [
    // Основная палитра
    const Color(0xFF26C6DA), // Бирюзовый
    const Color(0xFF9C27B0), // Фиолетовый
    const Color(0xFF00BCD4), // Темно-бирюзовый
    const Color(0xFF673AB7), // Тёмно-фиолетовый
    
    // Дополнительные цвета
    const Color(0xFFFF5722), // Оранжевый
    const Color(0xFF4CAF50), // Зелёный
    const Color(0xFF2196F3), // Синий
    const Color(0xFFE91E63), // Розовый
    
    // Пастельные
    const Color(0xFF4DD0E1), // Светло-бирюзовый
    const Color(0xFFBA68C8), // Светло-фиолетовый
    const Color(0xFFFFB74D), // Пастельный оранжевый
    const Color(0xFF81C784), // Пастельный зелёный
    
    // Яркие акценты
    const Color(0xFF18FFFF), // Яркий бирюзовый
    const Color(0xFFE040FB), // Яркий фиолетовый
    const Color(0xFFFF6D00), // Яркий оранжевый
    const Color(0xFF00E676), // Яркий зелёный
    
    // Нейтральные
    const Color(0xFF607D8B), // Сине-серый
    const Color(0xFF795548), // Коричневый
    const Color(0xFF9E9E9E), // Серый
    const Color(0xFF455A64), // Тёмно-серый
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subject == null ? 'Добавить предмет' : 'Редактировать предмет'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название предмета'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Выберите цвет:'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableColors.length,
                itemBuilder: (context, index) {
                  final color = _availableColors[index];
                  final isSelected = _selectedColor == color;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ] : null,
                      ),
                      child: isSelected 
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.isNotEmpty
              ? () {
                  if (widget.subject == null) {
                    // Добавляем новый предмет
                    final subject = Subject(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      color: _selectedColor,
                      description: _descriptionController.text.isNotEmpty 
                          ? _descriptionController.text 
                          : null,
                      createdAt: DateTime.now(),
                    );
                    context.read<SubjectsBloc>().add(AddSubject(subject));
                  } else {
                    // Обновляем существующий предмет
                    final updatedSubject = Subject(
                      id: widget.subject!.id,
                      name: _nameController.text,
                      color: _selectedColor,
                      description: _descriptionController.text.isNotEmpty 
                          ? _descriptionController.text 
                          : null,
                      createdAt: widget.subject!.createdAt,
                    );
                    context.read<SubjectsBloc>().add(UpdateSubject(updatedSubject));
                  }
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(widget.subject == null ? 'Добавить' : 'Сохранить'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}