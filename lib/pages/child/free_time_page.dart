import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/storage_service.dart';

class FreeTimePage extends StatefulWidget {
  const FreeTimePage({super.key});

  @override
  State<FreeTimePage> createState() => _FreeTimePageState();
}

class _FreeTimePageState extends State<FreeTimePage> {
  Timer? _timer;
  int _remainingCredits = 0;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _remainingCredits = storageService.getTotalCredits();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startUsingCredits() {
    if (_remainingCredits <= 0) {
      _showNoCreditsDialog();
      return;
    }

    setState(() => _isActive = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingCredits <= 0) {
        _stopUsingCredits();
        _showCreditsExhaustedDialog();
        return;
      }

      await storageService.spendCredits(1);
      
      if (mounted) {
        setState(() {
          _remainingCredits = storageService.getTotalCredits();
        });
      }
    });
  }

  void _stopUsingCredits() {
    _timer?.cancel();
    setState(() => _isActive = false);
  }

  void _showNoCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sin Créditos'),
        content: const Text(
          '¡No tienes tiempo libre disponible!\n\nCompleta tareas de estudio para ganar más.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showCreditsExhaustedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Tiempo Agotado!'),
        content: const Text(
          'Se acabó tu tiempo libre.\n\nEstudia más para ganar créditos adicionales.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final hours = _remainingCredits ~/ 3600;
    final minutes = (_remainingCredits % 3600) ~/ 60;
    final seconds = _remainingCredits % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isActive) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tiempo Libre'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isActive) {
                _showExitConfirmation();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple[700]!,
                Colors.purple[900]!,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon
                  Icon(
                    _isActive ? Icons.videogame_asset : Icons.hourglass_empty,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Timer Display
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: _isActive ? Colors.green : Colors.white,
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isActive ? Colors.green : Colors.purple)
                              .withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isActive ? 'En Uso' : 'Disponible',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Control Button
                  ElevatedButton(
                    onPressed: _isActive ? _stopUsingCredits : _startUsingCredits,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isActive ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isActive ? Icons.pause : Icons.play_arrow, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          _isActive ? 'Pausar' : 'Comenzar',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Info Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withOpacity(0.9),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isActive
                                ? 'Disfruta tu tiempo ganado 🎮'
                                : 'Presiona "Comenzar" para usar tu tiempo libre',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Detener Tiempo Libre?'),
        content: const Text(
          'Si sales ahora, se detendrá el contador.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _stopUsingCredits();
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
