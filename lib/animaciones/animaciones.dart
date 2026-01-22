import 'dart:math';
import 'package:flutter/material.dart';

enum AnimType { rotate, slideSide, slideDown, slideUp, pulse }

class AnimatedIconBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool isDone;
  final bool isLoading;
  final VoidCallback onTap;
  final AnimType animType;

  const AnimatedIconBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.isDone,
    required this.onTap,
    required this.animType,
    this.isLoading = false,
  });

  @override
  State<AnimatedIconBtn> createState() => _AnimatedIconBtnState();
}

class _AnimatedIconBtnState extends State<AnimatedIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkAnimation();
  }

  @override
  void didUpdateWidget(AnimatedIconBtn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAnimation();
  }

  void _checkAnimation() {
    bool shouldAnimate = false;
    // 1. Caso CARGANDO (Slide Side): Anima mientras esté cargando
    if (widget.animType == AnimType.slideSide) {
      if (widget.isLoading) shouldAnimate = true;
    }
    // 2. Caso TURBINA (Rotate): Anima mientras NO esté detenida (isDone)
    else if (widget.animType == AnimType.rotate) {
      if (!widget.isDone) shouldAnimate = true;
    }
    // 3. RESTO (Gota, Agua, Power): Animan si están ACTIVOS y NO TERMINADOS
    else {
      if (widget.isActive && !widget.isDone) shouldAnimate = true;
    }

    if (shouldAnimate && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: widget.animType != AnimType.rotate);
    } else if (!shouldAnimate) {
      _ctrl.stop();
      if (widget.animType == AnimType.rotate) _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDone
        ? Colors.green.withOpacity(0.2)
        : (widget.isActive ? Colors.black45 : Colors.black12);
    Color fg = widget.isDone
        ? Colors.green
        : (widget.isActive ? widget.color : Colors.grey.withOpacity(0.3));
    Color border = widget.isDone
        ? Colors.green
        : (widget.isActive ? widget.color : Colors.grey.withOpacity(0.1));

    return GestureDetector(
      onTap: widget.isActive && !widget.isDone ? widget.onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: widget.isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: widget.isDone
                  ? const Icon(
                      Icons.check_circle,
                      size: 28,
                      color: Colors.green,
                    )
                  : _buildAnimatedIcon(fg),
            ),
            const SizedBox(width: 10),
            Text(
              widget.isDone ? "OK" : widget.label,
              style: TextStyle(
                color: widget.isDone
                    ? Colors.green
                    : (widget.isActive ? Colors.white : Colors.white24),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(Color color) {
    Widget iconWidget = Icon(widget.icon, size: 28, color: color);

    switch (widget.animType) {
      case AnimType.rotate:
        return RotationTransition(turns: _ctrl, child: iconWidget);
      case AnimType.slideSide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.2, 0),
            end: const Offset(0.2, 0),
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
          child: iconWidget,
        );
      case AnimType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: const Offset(0, 0.2),
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
          child: iconWidget,
        );
      case AnimType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: const Offset(0, -0.2),
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
          child: iconWidget,
        );
      case AnimType.pulse:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.1,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
          child: iconWidget,
        );
    }
  }
}

//  BOTÓN DE EMERGENCIA
class BigRedButton extends StatefulWidget {
  final bool isActive;
  final bool isDone;
  final VoidCallback onTap;

  const BigRedButton({
    super.key,
    required this.isActive,
    required this.isDone,
    required this.onTap,
  });

  @override
  State<BigRedButton> createState() => _BigRedButtonState();
}

class _BigRedButtonState extends State<BigRedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si está activo (disponible) y no terminado, tiembla.
    if (widget.isActive && !widget.isDone) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
    }

    return GestureDetector(
      onTap: widget.isActive ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          double offset = (widget.isActive && !widget.isDone)
              ? sin(_ctrl.value * pi) * 3
              : 0;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: widget.isActive
                      ? [const Color(0xFFFF5252), const Color(0xFFB71C1C)]
                      : [Colors.grey.shade800, Colors.black],
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: widget.isActive
                      ? Colors.redAccent
                      : Colors.grey.shade800,
                  width: 4,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 50,
                  color: widget.isActive ? Colors.white : Colors.white24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- BARRAS DE ESTADO ---
class GaugeBar extends StatelessWidget {
  final String label;
  final double percentage;
  final double maxLimit;
  final String unit;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  const GaugeBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.maxLimit,
    required this.unit,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.linear,
                      width: double.infinity,
                      height:
                          constraints.maxHeight * percentage.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [colorStart, colorEnd],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        // TEXTOS GRANDES
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "${(percentage * maxLimit).toInt()}$unit",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
