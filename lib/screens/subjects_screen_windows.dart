import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/subjects_bloc_windows.dart';
import '../models/subject_windows.dart';
import '../theme/windows_theme.dart';

class SubjectsScreenWindows extends StatelessWidget {
  const SubjectsScreenWindows({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Предметы',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                BlocBuilder<SubjectsBloc, SubjectsState>(
                  builder: (context, state) {
                    if (state is SubjectsLoaded) {
                      return Text(
                        '${state.subjects.length} предметов',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          WindowsButton(
            text: 'Новый предмет',
            icon: Icons.add,
            onPressed: () => _createNewSubject(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<SubjectsBloc, SubjectsState>(
      builder: (context, state) {
        if (state is SubjectsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SubjectsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки предметов',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 24),
                WindowsButton(
                  text: 'Попробовать снова',
                  onPressed: () {
                    context.read<SubjectsBloc>().add(LoadSubjects());
                  },
                ),
              ],
            ),
          );
        }

        if (state is SubjectsLoaded) {
          if (state.subjects.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: state.subjects.length,
            itemBuilder: (context, index) {
              return _buildSubjectCard(context, state.subjects[index]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет предметов',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первый предмет для организации задач',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          WindowsButton(
            text: 'Создать предмет',
            icon: Icons.add,
            onPressed: () => _createNewSubject(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    return WindowsCard(
      onTap: () => _editSubject(context, subject),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: subject.colorValue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                subject.abbreviation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subject.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subject.description != null && subject.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subject.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _createNewSubject(BuildContext context) {
    _showSubjectDialog(context, null);
  }

  void _editSubject(BuildContext context, Subject subject) {
    _showSubjectDialog(context, subject);
  }

  void _showSubjectDialog(BuildContext context, Subject? subject) {
    showDialog(
      context: context,
      builder: (context) => _SubjectDialog(subject: subject),
    );
  }
}

class _SubjectDialog extends StatefulWidget {
  final Subject? subject;

  const _SubjectDialog({this.subject});

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = Subject.predefinedColors[0];

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _descriptionController.text = widget.subject!.description ?? '';
      _selectedColor = widget.subject!.colorValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject != null ? 'Редактировать предмет' : 'Новый предмет',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название предмета',
                      hintText: 'Математика, Физика, История...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название предмета';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание (необязательно)',
                      hintText: 'Краткое описание предмета...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Цвет',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: Subject.predefinedColors.map((color) {
                      final isSelected = color == _selectedColor;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 3,
                                  )
                                : null,
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
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.subject != null) ...[
                  TextButton.icon(
                    onPressed: _deleteSubject,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Удалить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                WindowsButton(
                  text: widget.subject != null ? 'Сохранить' : 'Создать',
                  onPressed: _saveSubject,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSubject() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final subject = Subject(
      id: widget.subject?.id ?? '',
      userId: '', // Будет установлен в BLoC
      name: _nameController.text.trim(),
      color: _selectedColor.value,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      createdAt: widget.subject?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.subject != null) {
      context.read<SubjectsBloc>().add(UpdateSubject(subject));
    } else {
      context.read<SubjectsBloc>().add(AddSubject(subject));
    }

    Navigator.pop(context);
  }

  void _deleteSubject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить предмет'),
        content: Text(
          'Вы уверены, что хотите удалить предмет "${widget.subject!.name}"? '
          'Все связанные задачи также будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          WindowsButton(
            text: 'Удалить',
            isPrimary: false,
            onPressed: () {
              Navigator.pop(context); // Закрыть диалог подтверждения
              Navigator.pop(context); // Закрыть диалог редактирования
              context.read<SubjectsBloc>().add(DeleteSubject(widget.subject!.id));
            },
          ),
        ],
      ),
    );
  }
}