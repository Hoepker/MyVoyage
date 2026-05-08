module.exports = function (api) {
  api.cache(true);
  return {
    presets: [['babel-preset-expo', { jsxImportSource: 'react' }]],
    plugins: [
      // react-native-worklets/plugin must be last (Reanimated v4 moved the plugin here)
      'react-native-worklets/plugin',
    ],
  };
};
