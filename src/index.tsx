import { NativeModules } from 'react-native';

type RouxSdkType = {
  multiply(a: number, b: number): Promise<number>;
};

const { RouxSdk } = NativeModules;

export default RouxSdk as RouxSdkType;
