import 'package:flutter/material.dart';
import '../models/record_model.dart';

class RecordCard extends StatelessWidget {

  final Record record;

  const RecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context){

    return Card(
      child: ListTile(
        title: Text(record.category),
        subtitle: Text("${record.value} ${record.unit}"),
        trailing: Text(record.timestamp),
      ),
    );

  }
}