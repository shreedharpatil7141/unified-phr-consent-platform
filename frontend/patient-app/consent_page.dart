import 'package:flutter/material.dart';

class ConsentPage extends StatelessWidget {

  void approve(BuildContext context){
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Consent Approved")));
  }

  void deny(BuildContext context){
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Consent Denied")));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Consent Request"),
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: ListTile(
                title: Text("City Care Hospital"),
                subtitle: Text("Request: Past 6 months history"),
              ),
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                ElevatedButton(
                  onPressed: (){
                    approve(context);
                  },
                  child: Text("Approve"),
                ),

                ElevatedButton(
                  onPressed: (){
                    deny(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  child: Text("Deny"),
                )

              ],
            )

          ],
        ),
      ),
    );
  }
}