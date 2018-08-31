package com.zhixi.rn_baidu_tts;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import android.content.Context;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import com.baidu.tts.auth.AuthInfo;
import com.baidu.tts.client.SpeechError;
import com.baidu.tts.client.SpeechSynthesizeBag;
import com.baidu.tts.client.SpeechSynthesizer;
import com.baidu.tts.client.SpeechSynthesizerListener;
import com.baidu.tts.client.SynthesizerTool;
import com.baidu.tts.client.TtsMode;
import java.util.List;
import java.util.Locale;
import android.os.Bundle;
import android.os.Environment;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.*;

public class TTSModule extends ReactContextBaseJavaModule implements SpeechSynthesizerListener
{
    private Context context;


    private static final String TAG = "RNbaiduTTS";


    private SpeechSynthesizer mSpeechSynthesizer; // TTS对象

    private String mSampleDirPath;
    private static final String SAMPLE_DIR_NAME = "baiduTTS";
    private static final String SPEECH_FEMALE_MODEL_NAME = "bd_etts_speech_female.dat";
    private static final String SPEECH_MALE_MODEL_NAME = "bd_etts_speech_male.dat";
    private static final String TEXT_MODEL_NAME = "bd_etts_text.dat";
    private static final String LICENSE_FILE_NAME = "temp_license_2017-08-15";
    private static final String Event_Name = "REACT_NATIVE_BAIDU_TTS";
    // private static final String APP_ID = "";//请更换为自己创建的应用
    // private static final String API_KEY = "";//请更换为自己创建的应用
    // private static final String SECRET_KEY = "";//请更换为自己创建的应用
    public TTSModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
        initialEnv();//获取离线资源路径
        // init();// 获取语音合成对象实例
    }

    private void initialEnv() {
        if (mSampleDirPath == null) {
            String sdcardPath = Environment.getExternalStorageDirectory().toString();
            Log.i(TAG, ">>>" + sdcardPath);
            mSampleDirPath = sdcardPath + "/" + SAMPLE_DIR_NAME;
            Log.i(TAG, ">>>" + mSampleDirPath);
        }
        File file = new File(mSampleDirPath);
        if (!file.exists()) {
            Log.i(TAG, "no");
            file.mkdirs();
        }
        Log.i(TAG, "yes");
        copyFromAssetsToSdcard(false, SPEECH_FEMALE_MODEL_NAME, mSampleDirPath + "/" + SPEECH_FEMALE_MODEL_NAME);
        copyFromAssetsToSdcard(false, SPEECH_MALE_MODEL_NAME, mSampleDirPath + "/" + SPEECH_MALE_MODEL_NAME);
        copyFromAssetsToSdcard(false, TEXT_MODEL_NAME, mSampleDirPath + "/" + TEXT_MODEL_NAME);
        copyFromAssetsToSdcard(false, LICENSE_FILE_NAME, mSampleDirPath + "/" + LICENSE_FILE_NAME);

    }

    /**
     * 将工程需要的资源文件拷贝到手机内存
     *
     * @param isCover 是否覆盖已存在的目标文件
     * @param source
     * @param dest
     */
    public void copyFromAssetsToSdcard(boolean isCover, String source, String dest) {
        File file = new File(dest);
        if (isCover || (!isCover && !file.exists())) {
            InputStream is = null;
            FileOutputStream fos = null;
            try {
                is = context.getResources().getAssets().open(source);
                String path = dest;
                fos = new FileOutputStream(path);
                byte[] buffer = new byte[1024];
                int size = 0;
                while ((size = is.read(buffer, 0, 1024)) >= 0) {
                    fos.write(buffer, 0, size);
                }
            } catch (FileNotFoundException e) {
                Log.i(TAG, ">>>1"+e);
                e.printStackTrace();
            } catch (IOException e) {
                Log.i(TAG, ">>>2"+e);
                e.printStackTrace();
            } finally {
                if (fos != null) {
                    try {
                        fos.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
                try {
                    if (is != null) {
                        is.close();
                    }
                } catch (IOException e) {
                    Log.i(TAG, ">>>3"+e);
                    e.printStackTrace();
                }
            }
        }
    }


    @Override
    public String getName(){
        return TAG;
    }

    /**
     * 初始化语音合成客户端并启动
     */
    @ReactMethod
    public void init(String appID, String apiKey, String secKey, Promise promise) {
        //获取语音合成对象实例
        this.mSpeechSynthesizer = SpeechSynthesizer.getInstance();
        //设置Context
        this.mSpeechSynthesizer.setContext(context);

        //文本模型文件路径 (离线引擎使用)
        this.mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_TTS_TEXT_MODEL_FILE, mSampleDirPath + "/"
                + TEXT_MODEL_NAME);
        //声学模型文件路径 (离线引擎使用)
        this.mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_TTS_SPEECH_MODEL_FILE, mSampleDirPath + "/"
                + SPEECH_FEMALE_MODEL_NAME);
        Log.i(TAG, ">>>111"+mSampleDirPath + "/"
                + SPEECH_FEMALE_MODEL_NAME);

        //请替换为语音开发者平台上注册应用得到的App ID (离线授权)
        this.mSpeechSynthesizer.setAppId(appID);
        // 请替换为语音开发者平台注册应用得到的apikey和secretkey (在线授权)
        this.mSpeechSynthesizer.setApiKey(apiKey, secKey);
        //发音人（在线引擎），可用参数为0,1,2,3。。。
        //（服务器端会动态增加，各值含义参考文档，以文档说明为准。0--普通女声，1--普通男声，2--特别男声，3--情感男声。。。）
        this.mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_SPEAKER, "0");
        // 设置Mix模式的合成策略
        this.mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_MIX_MODE, SpeechSynthesizer.MIX_MODE_DEFAULT);

        this.mSpeechSynthesizer.setSpeechSynthesizerListener(this);
        // 授权检测接口(可以不使用，只是验证授权是否成功)
        AuthInfo authInfo = this.mSpeechSynthesizer.auth(TtsMode.MIX);
        // this.mSpeechSynthesizer.initTts(TtsMode.MIX);
        if (authInfo.isSuccess()) {
            Log.i(TAG, ">>>auth success.");
            // 引擎初始化tts接口
            int result = this.mSpeechSynthesizer.initTts(TtsMode.MIX);
            if(result == 0) promise.resolve(result);
            else promise.reject("-1","init error");
        } else {
            String errorMsg = authInfo.getTtsError().getDetailMessage();
            Log.i(TAG, ">>>auth failed errorMsg: " + errorMsg);
            promise.reject("auth failed errorMsg",errorMsg);
        }
    }

    @ReactMethod
    public void speak(String text, Promise promise) {
        if (mSpeechSynthesizer != null) {
            //语言合成
            Log.i(TAG,"播报");
            int result = mSpeechSynthesizer.speak(text);
            if(result == 0)  promise.resolve(result);
            else  promise.reject("-1","init error");
        }
    }

    @ReactMethod
    public void stop(){
        mSpeechSynthesizer.stop();
    }

    @ReactMethod
    public void pause(){
        mSpeechSynthesizer.pause();
    }

    @ReactMethod
    public void resume(){
        mSpeechSynthesizer.resume();
    }

    @Override
    public void onSynthesizeStart(String s) {
        Log.i(TAG, "onSynthesizeStart");
        sendEvent("syn-start", s);
    }

    @Override
    public void onSynthesizeDataArrived(String s, byte[] bytes, int i) {
        Log.i(TAG, "onSynthesizeDataArrived: ");
        sendEvent("syn-data", s);
    }

    @Override
    public void onSynthesizeFinish(String s) {
        Log.i(TAG, "onSynthesizeFinish: ");
        sendEvent("syn-end", s);
    }

    @Override
    public void onSpeechStart(String s) {
        Log.i(TAG, "onSpeechStart: ");
        sendEvent("speech-start", s);
    }

    @Override
    public void onSpeechProgressChanged(String s, int i) {
        Log.i(TAG, "onSpeechProgressChanged: ");
        sendEvent("speech-progress", s);
    }

    @Override
    public void onSpeechFinish(String s) {
        Log.i(TAG, "onSpeechFinish: ");
        sendEvent("speech-end", s);
    }

    @Override
    public void onError(String s, SpeechError speechError) {
        Log.i(TAG, "onError: "+speechError.code);
        sendEvent("error", ""+speechError.code);
    }

    private void sendEvent(String eventName, String utteranceId) {
        WritableMap params = Arguments.createMap();
        params.putString("name", eventName);
        params.putString("speekSentenceID", utteranceId);
        getReactApplicationContext()
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(Event_Name, params);
    }
}
