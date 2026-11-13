# Nomindo iOS — Mac Olmadan iPhone'a Gerçek Uygulama Kurulum Rehberi

Bu klasör, **Nomindo** uygulamasının gerçek **Swift / SwiftUI** kaynak kodlarını, **Apple Vision AI Vücut İskeleti Takip Motorunu** ve Mac olmadan bulutta `.ipa` kurulum dosyası üretmenizi sağlayan **`codemagic.yaml`** yapılandırmasını içerir.

## Adım 1: GitHub'a Yükleme (2 Dakika)
1. [github.com](https://github.com) adresinde ücretsiz bir hesap açın ve **"New repository"** butonuna basarak `nomindo-ios` adında yeni bir depo (repository) oluşturun.
2. **"uploading an existing file"** bağlantısına tıklayın ve bu ZIP içindeki tüm dosya ve klasörleri (`project.yml`, `codemagic.yaml` ve `Nomindo` klasörü) doğrudan sürükleyip **Commit changes** deyin.

## Adım 2: Codemagic ile Mac Olmadan `.ipa` Üretme
1. [codemagic.io](https://codemagic.io) adresine gidin ve **Sign up with GitHub** ile giriş yapın.
2. Listeden `nomindo-ios` projenizi seçin.
3. Codemagic otomatik olarak `codemagic.yaml` dosyasını tanıyacaktır. Sağ üstteki **Start new build** butonuna basın.
4. Yaklaşık 3-5 dakika içinde buluttaki Mac sunucusu uygulamayı sıfır hatayla derleyecek ve sağ taraftaki **Artifacts** bölümünde **`Nomindo.ipa`** dosyasını indirmeye açacaktır. Dosyayı Windows bilgisayarınıza indirin.

## Adım 3: Sideloadly ile iPhone'unuza Kurma
1. Windows bilgisayarınıza ücretsiz [sideloadly.io](https://sideloadly.io) programını indirip kurun (bilgisayarınızda iTunes veya Apple Devices uygulamasının yüklü olması gerekir).
2. iPhone'unuzu USB kablosuyla bilgisayara bağlayın ve telefonda çıkan **"Bu Bilgisayara Güven"** uyarısını onaylayın.
3. Sideloadly programını açın, indirdiğiniz **`Nomindo.ipa`** dosyasını Sideloadly penceresine sürükleyin.
4. **Apple ID** kutusuna kendi Apple kimliğinizi yazın ve **Start** butonuna basın.
5. Kurulum bittiğinde iPhone ana ekranınızda **Nomindo** uygulaması görünecektir.
6. Uygulamayı ilk kez açmadan önce iPhone'da: **Ayarlar > Genel > VPN ve Aygıt Yönetimi** bölümüne girip kendi Apple ID profilinize dokunun ve **"Güven"** deyin.
