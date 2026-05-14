package com.kalan.gemma

class GemmaBridge {
    companion object {
        init {
            System.loadLibrary("gemma_jni")
        }
    }
    
    external fun loadModel(path: String, nCtx: Int, nThreads: Int)
    external fun generate(prompt: String, maxTokens: Int, temperature: Float): String
    external fun unloadModel()
}
