import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { PropertyRecord } from '../lib/questions';
const KEY='mirath-melk-properties-v1';
type State={properties:PropertyRecord[];hydrated:boolean;hydrate:()=>Promise<void>;add:(p:PropertyRecord)=>Promise<void>};
export const usePropertyStore=create<State>((set,get)=>({properties:[],hydrated:false,hydrate:async()=>{try{const raw=await AsyncStorage.getItem(KEY);set({properties:raw?JSON.parse(raw):[],hydrated:true})}catch{set({hydrated:true})}},add:async(p)=>{const properties=[p,...get().properties];set({properties});await AsyncStorage.setItem(KEY,JSON.stringify(properties));}}));