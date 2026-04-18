export * from './models';

export type RootStackParamList = {
  Login: undefined;
  Home: undefined;
  TestConfig: { bookName: string; unitName: string };
  ActiveTest: undefined;
  PostTestSummary: undefined;
  HistoryList: undefined;
  MistakeBook: undefined;
  About: undefined;
};