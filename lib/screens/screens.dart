import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:panel_control/animaciones/animaciones.dart';

class ControlRoomPage extends StatefulWidget {
  const ControlRoomPage({super.key});

  @override
  State<ControlRoomPage> createState() => _ControlRoomPageState();
}

class _ControlRoomPageState extends State<ControlRoomPage>
    with TickerProviderStateMixin {
  Timer? _simTimer;

  // --- FÍSICA ---
  double _waterLevel = 1.0;
  double _tempLevel = 0.0;
  double _energyOutput = 1000;

  double _pressurePsi = 2000.0;
  double _radiationmSv = 0.04;
  double _flowRate = 100.0;

  int _secondsRemaining = 30;

  // ESTADOS
  bool _turbinasDetenidas = false;
  bool _ventilacionCompletada = false;
  bool _aguaEvacuada = false;
  bool _aguaReemplazada = false;
  bool _reactorApagado = false;
  bool _emergenciaActivada = false;

  bool _ventilando = false;
  bool _meltdown = false;

  @override
  void initState() {
    super.initState();
    _iniciarSimulacion();
  }

  void _iniciarSimulacion() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_emergenciaActivada || _meltdown) return;

      setState(() {
        if (timer.tick % 10 == 0) _secondsRemaining--;

        if (!_reactorApagado) {
          _waterLevel -= 0.003;
          _tempLevel = 1.0 - _waterLevel;
          if (!_turbinasDetenidas) {
            _energyOutput = (_waterLevel * 1000) + Random().nextInt(20);
          }
        }

        if (_waterLevel < 0) _waterLevel = 0;
        if (_waterLevel > 1) _waterLevel = 1;
        _tempLevel = 1.0 - _waterLevel;
        if (_tempLevel < 0) _tempLevel = 0;
        if (_tempLevel > 1) _tempLevel = 1;

        _pressurePsi = 2000 + (_tempLevel * 2000);
        _flowRate = _waterLevel * 100;
        _radiationmSv = _ventilacionCompletada
            ? 0.02
            : (0.04 + _tempLevel * 0.8);

        if (_secondsRemaining <= 0 || _waterLevel <= 0) {
          _secondsRemaining = 0;
          _waterLevel = 0;
          _tempLevel = 1.0;
          _meltdown = true;
          _simTimer?.cancel();
          _mostrarAlerta(
            "¡FUSIÓN DEL NÚCLEO!\nTemperatura Crítica.",
            Colors.red,
          );
        }
      });
    });
  }

  void _accionDetenerTurbinas() => setState(() => _turbinasDetenidas = true);

  void _accionVentilar() {
    if (!_turbinasDetenidas || _ventilacionCompletada) return;
    setState(() => _ventilando = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_meltdown)
        setState(() {
          _ventilando = false;
          _ventilacionCompletada = true;
        });
    });
  }

  void _accionEvacuarAgua() {
    if (!_ventilacionCompletada || _aguaEvacuada) return;
    setState(() {
      _waterLevel = 0.05;
      _tempLevel = 0.95;
      _aguaEvacuada = true;
    });
  }

  void _accionInyectarAgua() {
    if (!_aguaEvacuada || _aguaReemplazada) return;
    setState(() {
      _waterLevel = 1.0;
      _tempLevel = 0.0;
      _aguaReemplazada = true;
    });
  }

  void _accionApagarReactor() {
    if (!_aguaReemplazada || _reactorApagado) return;
    setState(() => _reactorApagado = true);
  }

  void _accionEmergencia() {
    if (!_reactorApagado) return;
    setState(() => _emergenciaActivada = true);
    _simTimer?.cancel();
    _mostrarAlerta("SISTEMA ESTABILIZADO.\nBUEN TRABAJO.", Colors.green);
  }

  void _mostrarAlerta(String titulo, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: color.withOpacity(0.95),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          color == Colors.red
              ? "Fallo catastrófico del sistema."
              : "Protocolos completados correctamente.",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _waterLevel = 1.0;
                _tempLevel = 0.0;
                _energyOutput = 1000;
                _secondsRemaining = 30;
                _turbinasDetenidas = false;
                _ventilacionCompletada = false;
                _aguaEvacuada = false;
                _aguaReemplazada = false;
                _reactorApagado = false;
                _emergenciaActivada = false;
                _meltdown = false;
              });
              _iniciarSimulacion();
            },
            child: const Text(
              "REINICIAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // COLUMNA 1: BOTONES (CONTROL)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text(
                      "CONTROL",
                      style: TextStyle(
                        color: Colors.white24,
                        letterSpacing: 2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // 1. Turbina (Gira mientras está activa)
                    Expanded(
                      child: AnimatedIconBtn(
                        label: "PARAR TURBINA",
                        icon: Icons.cyclone,
                        color: Colors.cyan,
                        isActive: !_turbinasDetenidas,
                        isDone: _turbinasDetenidas,
                        onTap: _accionDetenerTurbinas,
                        animType: AnimType.rotate,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Ventilar (Viento: ESTÁTICO a menos que esté ventilando)
                    Expanded(
                      child: AnimatedIconBtn(
                        label: "VENTILAR GAS",
                        icon: Icons.air, // ICONO VIENTO
                        color: Colors.lightGreenAccent, // VERDE PASTEL
                        isActive: _turbinasDetenidas && !_ventilacionCompletada,
                        isDone: _ventilacionCompletada,
                        onTap: _accionVentilar,
                        isLoading: _ventilando,
                        animType: AnimType.slideSide,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3A. Evacuar (Gota cayendo mientras espera)
                    Expanded(
                      child: AnimatedIconBtn(
                        label: "DRENAR AGUA",
                        icon: Icons.water_drop,
                        color: Colors.orange,
                        isActive: _ventilacionCompletada && !_aguaEvacuada,
                        isDone: _aguaEvacuada,
                        onTap: _accionEvacuarAgua,
                        animType: AnimType.slideDown,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3B. Inyectar (Agua subiendo mientras espera)
                    Expanded(
                      child: AnimatedIconBtn(
                        label: "LLENAR TANQUE",
                        icon: Icons.water,
                        color: Colors.blue,
                        isActive: _aguaEvacuada && !_aguaReemplazada,
                        isDone: _aguaReemplazada,
                        onTap: _accionInyectarAgua,
                        animType: AnimType.slideUp,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 4. Apagar (Palpita mientras espera)
                    Expanded(
                      child: AnimatedIconBtn(
                        label: "APAGAR NÚCLEO",
                        icon: Icons.power_settings_new,
                        color: Colors.purple,
                        isActive: _aguaReemplazada && !_reactorApagado,
                        isDone: _reactorApagado,
                        onTap: _accionApagarReactor,
                        animType: AnimType.pulse,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 5. EMERGENCIA (REDONDO)
                    const Text(
                      "DETENIDO DE EMERGENCIA",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      flex: 2,
                      child: BigRedButton(
                        isActive: _reactorApagado && !_emergenciaActivada,
                        isDone: _emergenciaActivada,
                        onTap: _accionEmergencia,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            // COLUMNA 2: INFO
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 4,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "> ESTADO_DEL_REACTOR",
                            style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          _buildRow(
                            "PRESION",
                            "${_pressurePsi.toInt()} PSI",
                            Colors.white70,
                          ),
                          _buildRow(
                            "RADIACION",
                            "${_radiationmSv.toStringAsFixed(2)} mSv",
                            _radiationmSv > 0.1 ? Colors.red : Colors.green,
                          ),
                          _buildRow(
                            "LIQUIDO REFRIGERANTE",
                            "${_flowRate.toInt()}%",
                            Colors.blue,
                          ),
                          _buildRow(
                            "ESTADO TURBINAS",
                            _turbinasDetenidas ? "OFF" : "ON",
                            Colors.orange,
                          ),
                          const Spacer(),
                          const Text(
                            "OUTPUT:",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            "${_energyOutput.toInt()} MW",
                            style: TextStyle(
                              color: _turbinasDetenidas
                                  ? Colors.yellow
                                  : Colors.cyanAccent,
                              fontSize: 32,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF220000),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.shade900,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "00:${_secondsRemaining.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontSize: 80,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // COLUMNA 3: MEDIDORES
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GaugeBar(
                      label: "TEMP",
                      percentage: _tempLevel,
                      maxLimit: 400,
                      unit: "°C",
                      colorStart: Colors.green,
                      colorEnd: Colors.red,
                      icon: Icons.thermostat,
                    ),
                    GaugeBar(
                      label: "AGUA",
                      percentage: _waterLevel,
                      maxLimit: 100,
                      unit: "%",
                      colorStart: Colors.red,
                      colorEnd: Colors.blue,
                      icon: Icons.water_drop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
