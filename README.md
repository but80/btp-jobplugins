# btp-jobplugins

## なにこれ

VOCALOID3で使用できるJob Pluginです。
各プラグインの説明は以下。

## vowel2gen.lua

### 用途

a, i, M, e, o の各母音に対応する値を設定することで、それぞれの母音を持つノートのGENの値を変更します。
日本語ライブラリにのみ対応しています。また、複数の母音を含むノートでは、最後の母音のみ認識されます。

### パラメータ

* **add to existing control** 既存のGENに加算するときはチェック
* **position offset** 位置のオフセット（VOCALOIDはGENの変化にやや遅れて追随するため、負の値を推奨）
* **GEN offset** 以下の全GENパラメータのオフセット（通常は0）
* **[a] GEN** 発音記号 a の母音を持つノートのGENオフセット（0は変化なし）
* **[i] GEN** 同 i
* **[M] GEN** 同 M
* **[e] GEN** 同 e
* **[o] GEN** 同 o
* **default GEN** 母音以外のノートのGENオフセット（空文字は直前のGENを維持する）

