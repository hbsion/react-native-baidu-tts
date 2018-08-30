/**
 * @file 百度语音合成 SDK
 * @author leon <lupengyu@baidu.com>
 */
import {
    NativeModules,
    NativeAppEventEmitter
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
    volume: 60
};

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

    return await Synthesizer.init(options);

}

/**
 * 合成并播放语句
 *
 * @param {string}    sentence 语句
 * @param {?Function} callback 事件回调
 * @return {Promise}
 */
export function speekSentence(sentence, callback) {

    assertRequiredParams(conf);

    callback = typeof callback === 'function' ? callback : noop;

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

                    callback(event);

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
    return await Synthesizer.cancel();
}

export async function getStatus() {
    return await Synthesizer.getStatus();
}

export async function setVolume(volume) {
    return await Synthesizer.setVolume(volume);
}