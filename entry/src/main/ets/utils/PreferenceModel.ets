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

  // 写入密码
  async getTenantId(userId:string) {
    return this.getPreference(`${userId}:tenantId`);
  }

  // 写入密码
  async setTenantId(userId:string,tenantId:string,) {
    await this.putPreference(`${userId}:tenantId`,tenantId);
  }
}

export default new PreferenceModel();