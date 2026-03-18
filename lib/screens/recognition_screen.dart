import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../widgets/drawing_canvas.dart';
import '../utils/image_utils.dart';
import '../services/classifier.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<DrawingCanvasState> _drawingKey = GlobalKey<DrawingCanvasState>();
  final DigitClassifier _classifier = DigitClassifier();

  ClassificationResult? _result;
  bool _isProcessing = false;
  bool _isModelLoading = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      setState(() => _isModelLoading = false);
    } catch (e) {
      setState(() {
        _isModelLoading = false;
        _errorMessage = 'Failed to load model: $e';
      });
    }
  }

  Future<void> _recognize() async {
    if (_isProcessing || !_classifier.isLoaded) return;

    final drawingState = _drawingKey.currentState;
    if (drawingState == null || !drawingState.hasStrokes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please draw a digit first!'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final input = await ImageUtils.captureAndProcess(boundary);
      final result = _classifier.classify(input);

      setState(() {
        _result = result;
        _isProcessing = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Recognition failed: $e';
      });
    }
  }

  void _clearCanvas() {
    _drawingKey.currentState?.clear();
    setState(() => _result = null);
    _animController.reset();
  }

  @override
  void dispose() {
    _animController.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final canvasSize = (screenWidth - 48).clamp(200.0, 400.0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(),
              const SizedBox(height: 24),

              // ── Error Banner ──
              if (_errorMessage != null) _buildErrorBanner(),

              // ── Drawing Area ──
              _buildCanvasArea(canvasSize),
              const SizedBox(height: 24),

              // ── Action Buttons ──
              _buildButtons(),
              const SizedBox(height: 28),

              // ── Result Display ──
              if (_result != null) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          ).createShader(bounds),
          child: const Text(
            'Digit Recognition',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Draw a digit below and let AI recognize it',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade200, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(double canvasSize) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: Stack(
              children: [
                DrawingCanvas(
                  key: _drawingKey,
                  repaintKey: _canvasKey,
                ),
                // Loading overlay
                if (_isModelLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF7C4DFF),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Loading model...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Processing overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C4DFF),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Clear Button
        OutlinedButton.icon(
          onPressed: _clearCanvas,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade300,
            side: BorderSide(color: Colors.grey.shade600),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Recognize Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _recognize,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(_isProcessing ? 'Processing...' : 'Recognize'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // Predicted digit
            Text(
              'Predicted Digit',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
              ).createShader(bounds),
              child: Text(
                '${_result!.predictedDigit}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Confidence: ${(_result!.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),

            // Confidence bars for all digits
            ...List.generate(10, (i) => _buildConfidenceBar(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(int digit) {
    final confidence = _result!.confidences[digit];
    final isMax = digit == _result!.predictedDigit;
    final percentage = (confidence * 100).clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isMax ? FontWeight.w800 : FontWeight.w400,
                color: isMax ? const Color(0xFF7C4DFF) : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                // Fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 22,
                  width: double.infinity,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: isMax
                            ? const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade700,
                                  Colors.grey.shade600,
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isMax ? FontWeight.w700 : FontWeight.w400,
                color: isMax ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
