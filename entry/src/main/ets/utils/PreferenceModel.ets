import dataPreferences from "@ohos.data.preferences";

let context = getContext(this);
let preference: dataPreferences.Preferences | null = null; // 初始化为 null

class PreferenceModel {
  // 确保首选项已初始化
  private async ensurePreferenceInitialized() {
    if (preference === null) {
      await this.getPreferencesFromStorage();
    }
  }

  // 初始化 Preferences 首选项
  async getPreferencesFromStorage() {
    try {
      preference = await dataPreferences.getPreferences(context, 'mystore');
    } catch (err) {
      console.error("Failed to get preferences:", err);
      preference = null; // 确保在出错时重置为 null
    }
  }

  // 删除 preferences 实例对应的首选项
  async deletePreferences() {
    try {
      await dataPreferences.deletePreferences(context, 'mystore');
    } catch (err) {
      console.error("Failed to delete preferences:", err);
    }
    preference = null; // 删除后重置为 null
  }

  // 设置 key-value
  async putPreference(key: string, value: string) {
    await this.ensurePreferenceInitialized();

    if (preference) {
      try {
        await preference.put(key, value);
        await preference.flush();
      } catch (err) {
        console.error(`Failed to put preference [${key}]:`, err);
      }
    } else {
      console.error("Preferences not initialized, cannot put value");
    }
  }

  // 获取 key 对应的 value
  async getPreference(key: string): Promise<string | null> {
    await this.ensurePreferenceInitialized();

    if (!preference) {
      console.error("Preferences not initialized, cannot get value");
      return null;
    }

    try {
      const value = await preference.get(key, null);
      return value !== null ? String(value) : null;
    } catch (err) {
      console.error(`Failed to get preference [${key}]:`, err);
      return null;
    }
  }

  // 删除 key 对应的 value
  async deletePreference(key: string) {
    await this.ensurePreferenceInitialized();

    if (preference) {
      try {
        await preference.delete(key);
        await preference.flush();
      } catch (err) {
        console.error(`Failed to delete preference [${key}]:`, err);
      }
    } else {
      console.error("Preferences not initialized, cannot delete value");
    }
  }

  // 获取 token
  async getToken() {
    return this.getPreference('token');
  }

  // 写入 token
  async setToken(token: string) {
    await this.putPreference('token', token);
  }

  // 获取密码
  async getPassword(userAccount: string): Promise<string | null> {
    return this.getPreference(userAccount);
  }

  // 写入密码
  async setPassword(userAccount: string, password: string) {
    await this.putPreference(userAccount, password);
  }

  // 获取电影搜索关键词
  async getMovieSearchKeyWord(): Promise<Array<string>> {
    const movieSearchKeyWord = await this.getPreference('movieSearchKeyWord');
    if (movieSearchKeyWord) {
      try {
        return JSON.parse(movieSearchKeyWord) as Array<string>;
      } catch (e) {
        console.error('Failed to parse movie search keywords:', e);
        return [];
      }
    } else {
      return [];
    }
  }

  // 设置电影搜索关键词
  async setMovieSearchKeyWord(keyWord: string): Promise<void> {
    const movieSearchKeyWord: Array<string> = await this.getMovieSearchKeyWord();
    const index = movieSearchKeyWord.findIndex(item => item === keyWord);

    if (index !== -1) {
      movieSearchKeyWord.splice(index, 1);
    }

    movieSearchKeyWord.unshift(keyWord);

    // 最多只存十条记录
    if (movieSearchKeyWord.length > 10) {
      movieSearchKeyWord.splice(10);
    }

    await this.putPreference('movieSearchKeyWord', JSON.stringify(movieSearchKeyWord));
  }
}

export default new PreferenceModel();