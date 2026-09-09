import * as Speech from 'expo-speech';
import { Audio } from 'expo-av';
export async function speak(text:string){await Speech.stop();Speech.speak(text,{language:'fa-IR',rate:0.9,pitch:1.05});}
export async function startRecording(){const perm=await Audio.requestPermissionsAsync();if(!perm.granted)throw new Error('اجازه دسترسی به میکروفون داده نشد.');await Audio.setAudioModeAsync({allowsRecordingIOS:true,playsInSilentModeIOS:true});const {recording}=await Audio.Recording.createAsync(Audio.RecordingOptionsPresets.HIGH_QUALITY);return recording;}
export async function stopRecording(recording:Audio.Recording){await recording.stopAndUnloadAsync();return recording.getURI()||undefined;}