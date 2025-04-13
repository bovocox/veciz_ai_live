import { defineStore } from 'pinia'
import { ref } from 'vue'
// Vue i18n kullanımını kaldırıyoruz
// import { useI18n } from 'vue-i18n'
// import trMessages from '../locales/tr.json'
// import enMessages from '../locales/en.json'
import { t as translate, setLocale, getCurrentLocale, getAvailableLocales } from '../utils/translations'

// EventBus için basit bir implementasyon
const eventBus = {
  listeners: {} as Record<string, Function[]>,
  on(event: string, callback: Function) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(callback);
  },
  emit(event: string, data?: any) {
    if (!this.listeners[event]) return;
    this.listeners[event].forEach(callback => callback(data));
  }
};

// Artık Messages tipini kaldırıyoruz
// type LocaleMessages = Record<string, any>
// 
// interface Messages {
//   [key: string]: LocaleMessages
// }

export const useLanguageStore = defineStore('language', () => {
  // Çeviri sisteminden mevcut dili alıyoruz
  const currentLocale = ref(getCurrentLocale())
  // Aynı değeri language referansında da tutuyoruz (uyumluluk için)
  const language = ref(getCurrentLocale())
  
  // Vue i18n artık kullanılmıyor
  // const i18n = useI18n()

  // Çeviri mesajlarını artık doğrudan kullanmıyoruz
  // const messages: Messages = {
  //   tr: trMessages as LocaleMessages,
  //   en: enMessages as LocaleMessages
  // }

  // Çeviri fonksiyonu artık doğrudan utils/translations'dan gelen t fonksiyonunu kullanıyor
  function t(key: string, replacements: Record<string, string> = {}) {
    return translate(key, replacements)
  }

  function setLanguage(lang: string, shouldReload: boolean = true) {
    // Sadece desteklenen diller için işlem yapıyoruz
    if (lang === 'tr' || lang === 'en') {
      console.log(`🌐 Dil değiştiriliyor: ${lang}, Yeniden Yükleme: ${shouldReload ? 'Evet' : 'Hayır'}`);
      
      // Mevcut dili güncelliyoruz
      currentLocale.value = lang;
      language.value = lang;
      
      // Çeviri sistemindeki dili değiştiriyoruz
      setLocale(lang as 'tr' | 'en');
      
      // Kullanıcının tercihini local storage'a kaydedelim
      localStorage.setItem('userLocale', lang);
      
      console.log(`✅ Dil değiştirildi: ${lang}, currentLocale: ${currentLocale.value}, Locale in Storage: ${localStorage.getItem('userLocale')}`);
      
      // Dil değişikliği olayını yayınla
      eventBus.emit('language-changed', lang);
      
      // Eğer zorunlu bir sayfa yenilemesi isteniyorsa
      if (shouldReload) {
        console.log('🔄 Sayfa yenileniyor...');
        setTimeout(() => {
          // Sayfayı yenile
          window.location.reload();
          console.log(`✅ Dil ayarlandı (sayfa yenilendi): ${currentLocale.value}`);
        }, 100);
      } else {
        // Sayfa yenilemeden çevirileri güncellemeye çalış
        console.log('📢 Sayfa yenilemeden dil değişikliği uygulandı - Bu bazı sayfalarda çalışmayabilir');
      }
    } else {
      console.warn(`⚠️ Desteklenmeyen dil: ${lang}`);
    }
  }

  // Dil değişikliği event listener'ı eklemek için fonksiyon
  function onLanguageChange(callback: (lang: string) => void) {
    eventBus.on('language-changed', callback);
  }

  return {
    currentLocale,
    language,
    // messages artık mevcut değil
    t,
    setLanguage,
    onLanguageChange
  }
})