import 'package:flutter/material.dart';

/// Pide un nombre. Devuelve null si se cancela.
///
/// Usa TextFormField con initialValue en vez de un TextEditingController
/// propio: el campo maneja y libera el suyo, así que no hay ni fuga ni
/// riesgo de liberarlo mientras el diálogo todavía está en pantalla.
Future<String?> mostrarNameDialog(
  BuildContext context, {
  required String titulo,
  required String actual,
}) {
  var texto = actual;

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: TextFormField(
        initialValue: actual,
        autofocus: true,
        onChanged: (valor) => texto = valor,
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
          onPressed: () => Navigator.pop(context, texto),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
