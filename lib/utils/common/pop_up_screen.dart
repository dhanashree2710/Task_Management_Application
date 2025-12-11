import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void showCustomAlert(
  BuildContext context, {
  required bool isSuccess,
  required String title,
  required String description,
  Widget? nextScreen,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                isSuccess ? 'assets/success.json' : 'assets/error.json',
                width: 100,
                height: 100,
                repeat: true,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  //Navigator.pop(context); // Close the dialog
                  if (nextScreen != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => nextScreen),
                    );
                  }
                },
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}
