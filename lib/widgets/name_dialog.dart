import 'package:flutter/material.dart';

/// Pide un nombre. Devuelve null si se cancela.
Future<String?> mostrarNameDialog(
  BuildContext context, {
  required String titulo,
  required String actual,
}) {
  final controller = TextEditingController(text: actual);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Ingresá el nombre',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
