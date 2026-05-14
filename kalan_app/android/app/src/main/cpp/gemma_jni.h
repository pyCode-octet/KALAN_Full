#ifndef GEMMA_JNI_H
#define GEMMA_JNI_H

#include <jni.h>

extern "C" {
    JNIEXPORT void JNICALL Java_com_kalan_gemma_GemmaBridge_loadModel(JNIEnv* env, jobject thiz, jstring path, jint nCtx, jint nThreads);
    JNIEXPORT jstring JNICALL Java_com_kalan_gemma_GemmaBridge_generate(JNIEnv* env, jobject thiz, jstring prompt, jint maxTokens, jfloat temperature);
    JNIEXPORT void JNICALL Java_com_kalan_gemma_GemmaBridge_unloadModel(JNIEnv* env, jobject thiz);
}

#endif // GEMMA_JNI_H
