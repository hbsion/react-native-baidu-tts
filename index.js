/**
 * @file 百度语音合成 SDK
 * @author leon <lupengyu@baidu.com>
 */
import {
    NativeModules,
    NativeAppEventEmitter,
    NativeEventEmitter,
    Platform,
} from 'react-native';

const Synthesizer = NativeModules.RNbaiduTTS;
const noop = function () {};

const APP_EVENT_NAME = 'REACT_NATIVE_BAIDU_TTS';

let conf = {
    tongue: 'female',
    offlineEngine: false,
    appID: '',
    apiKey: '',
    secretKey: '',
    volume: 120
};

class ANDRNbaiduTTS extends NativeEventEmitter {
    constructor() {
        console.log(NativeModules.RNbaiduTTS);
        super(NativeModules.RNbaiduTTS);
    }

    init = NativeModules.RNbaiduTTS.init;

    speak(content) {
        return NativeModules.RNbaiduTTS.speak(content);
    }
    stop () {
        return NativeModules.RNbaiduTTS.stop();
    }
    resume () {
        return NativeModules.RNbaiduTTS.resume();
    }
    pause () {
        return NativeModules.RNbaiduTTS.pause();
    }

    addEventListener(handler) {
        this.addListener(APP_EVENT_NAME, handler);
    }

    removeEventListener(handler) {
        this.removeListener(APP_EVENT_NAME, handler);
    }
}

const androidTTS = new ANDRNbaiduTTS();

function assertRequiredParams(options) {

    const {
        appID,
        apiKey,
        secretKey
    } = options;

    if (!appID) {
        throw new Error('appID is required');
    }

    if (!apiKey) {
        throw new Error('apiKey is required');
    }

    if (!secretKey) {
        throw new Error('secretKey is required');
    }

}

/**
 * 配置语音合成SDK
 *
 * @param {Object} options 配置
 * @return {Promise}
 */
export async function configure(options) {

    assertRequiredParams(options);

    options = conf = Object.assign({}, conf, options);

    // 兼容 android
    if(Platform.OS == "android") {
        console.log(options);
        return androidTTS.init(options['appID'],options['apiKey'],options['secretKey']);
    } else {
        return await Synthesizer.init(options);
    }
    
}

/**
 * 合成并播放语句
 *
 * @param {string}    sentence 语句
 * @param {?Function} callback 事件回调
 * @return {Promise}
 */
export async function speekSentence(sentence, callback) {

    assertRequiredParams(conf);

    callback = typeof callback === 'function' ? callback : noop;

    // console.log(sentence);
    if(Platform.OS == "android"){
        console.log("android",sentence);
        androidTTS.speak(sentence);
        return new Promise(function (resolve, reject) {
            subscription = androidTTS.addListener(APP_EVENT_NAME,function(event){
                const {
                    name,
                    speekSentenceID
                } = event;
                // console.log(event);
                if (name === 'error') {
                    subscription.remove();
                    reject(event);
                } else if (name === 'speech-end') {
                    subscription.remove();
                    resolve(event);
                }
                callback(event,subscription);
            })
        });
    }

    return Synthesizer.speekSentence(sentence).then(function (sentenceID) {

        callback({
            name: 'enquque',
            sentenceID
        });

        return new Promise(function (resolve, reject) {

            const subscription = NativeAppEventEmitter.addListener(
                APP_EVENT_NAME,
                function (event) {

                    const {
                        name,
                        speekSentenceID
                    } = event;

                    if (speekSentenceID !== sentenceID) {
                        return;
                    }

                    if (name === 'error') {
                        subscription.remove();
                        reject(event);
                    }
                    else if (name === 'speech-end') {
                        subscription.remove();
                        resolve(event);
                    }

                    callback(event,subscription);

                }
            );

        });

    });

}

// export async function synthesizeSentence(sentence, options) {
//
//     assertRequiredParams(options);
//
// }

export async function cancel() {
    if(Platform.OS=='android') {
        return androidTTS.stop();
        // return androidTTS.removeEventListener(APP_EVENT_NAME);
    }
    return await Synthesizer.cancel();
} 

export async function getStatus() {
    return await Synthesizer.getStatus();
}

export async function setVolume(volume) {
    return await Synthesizer.setVolume(volume);
}