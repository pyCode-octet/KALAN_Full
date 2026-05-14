package com.kalan.kalan.kalan_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.kalan.gemma.GemmaBridge

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kalan.gemma"
    private val gemmaBridge = GemmaBridge()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val path = call.argument<String>("modelPath")!!
                    val nCtx = call.argument<Int>("nCtx")!!
                    val nThreads = call.argument<Int>("nThreads")!!
                    gemmaBridge.loadModel(path, nCtx, nThreads)
                    result.success(null)
                }
                "generate" -> {
                    val prompt = call.argument<String>("prompt")!!
                    val maxTokens = call.argument<Int>("maxTokens")!!
                    val temperature = call.argument<Double>("temperature")!!.toFloat()
                    val output = gemmaBridge.generate(prompt, maxTokens, temperature)
                    result.success(output)
                }
                "unloadModel" -> {
                    gemmaBridge.unloadModel()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
