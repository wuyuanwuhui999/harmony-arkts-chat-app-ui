import api from '../api/index';
import httpRequest from '../utils/HttpUtil';
import * as types from '../type/Index'
import CryptoJS from '@ohos/crypto-js';
/**
 * @description: 根据token获取用户信息
 * @date: 2023-12-1 23:39
 * @author wuwenqiang
 */
export const getUserDataService = (token:string):Promise<types.MyAwesomeData<types.UserDataType>>=> {
  httpRequest.setToken(token);
  return httpRequest.get<types.UserDataType>(api.getUserData);
}

/**
 * @description: 注册
 * @date: 2024-01-21 14:48
 * @author wuwenqiang
 */
export const verifyUserService = (userAccount:string|undefined,email:string|undefined):Promise<types.MyAwesomeData<number>>=>{
  const params: types.VerifyUserParamsType = { userAccount, email };
  return httpRequest.post<number>(api.vertifyUser,params)
};

/**
 * @author: wuwenqiang
 * @description: 更新用户信息
 * @date: 2023-12-28 23:18
 */
export const updateUserDataService = (userData:types.UserDataType):Promise<types.MyAwesomeData<number>> => {
  return httpRequest.put<number>(api.updateUser,userData)
};

/**
 * @description: 登录
 * @date: 2024-01-15 21:32
 * @author wuwenqiang
 */
export const loginService = (userAccount:string,password:string):Promise<types.MyAwesomeData<types.UserDataType>>=> {
  password = CryptoJS.MD5(password).toString(); // 使用md5加密
  const params: types.LoginParamsType = { userAccount, password };
  return httpRequest.post<types.UserDataType>(api.login, params)
}


/**
 * @description: 注册
 * @date: 2024-01-19 23:51
 * @author wuwenqiang
 */
export const registerService = (userData:types.UserDataType):Promise<types.MyAwesomeData<types.UserDataType>> => {
  userData.password = CryptoJS.MD5(userData.password).toString(); // 使用md5加密
  return httpRequest.post<types.UserDataType>(api.register,userData)
};

/**
 * @description: 校验账号和密码是否存在
 * @date: 2024-01-19 23:51
 * @author wuwenqiang
 */
export const vertifyUserService = (userData:types.UserDataType):Promise<types.MyAwesomeData<number>> => {
  return httpRequest.post<number>(api.vertifyUser,userData)
};

/**
 * @description: 找回密码
 * @date: 2025-01-19 22:59
 * @author wuwenqiang
 */
export const sendEmailVertifyCodeService = (email:string):Promise<types.MyAwesomeData<number>> => {
  const params:types.EmailParamsType = {email}
  return httpRequest.post<number>(api.sendEmailVertifyCode,params)
};

export const resetPasswordService = (email:string,password:string,code:string):Promise<types.MyAwesomeData<types.UserDataType>>=>{
  password = CryptoJS.MD5(password).toString();// 使用md5加密
  const params: types.ResetPasswordParamsType = {email,password,code};
  return httpRequest.post<types.UserDataType>(api.resetPassword,params)
};

/**
 * @description: 更新密码
 * @date: 2025-01-28 14:22
 * @author wuwenqiang
 */
export const updatePasswordService = (oldPassword:string,newPassword:string):Promise<types.MyAwesomeData<number>> => {
  oldPassword = CryptoJS.MD5(oldPassword).toString();// 使用md5加密
  newPassword = CryptoJS.MD5(newPassword).toString();// 使用md5加密
  const params: types.UpdatePasswordParamsType = {oldPassword,newPassword};
  return httpRequest.put<number>(api.updatePassword,params)
};

/**
 * @description: 邮箱验证码登录
 * @date: 2025-01-28 14:22
 * @author wuwenqiang
 */
export const loginByEmailService = (email:string,code:string):Promise<types.MyAwesomeData<types.UserDataType>> => {
  const params:types.EmailCodeParamsType = {email,code};
  return httpRequest.post<types.UserDataType>(api.loginByEmail,params)
};

/**
 * @description: 获取聊天对话历史记录
 * @date: 2025-05-16 00:19
 * @author wuwenqiang
 */
export const getChatHistoryService = (pageNum:number,pageSize:number):Promise<types.MyAwesomeData<Array<types.ChatHistoryType>>> => {
  return httpRequest.get<Array<types.ChatHistoryType>>(`${api.getChatHistory}?pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 获取模型列表
 * @date: 2025-05-16 00:19
 * @author wuwenqiang
 */
export const getModelListService = ():Promise<types.MyAwesomeData<Array<types.ChatModelType>>> => {
  return httpRequest.get<Array<types.ChatModelType>>(api.getModelList)
}

/**
 * @description: 上传文档
 * @date: 2025-06-21 13:48
 * @author wuwenqiang
 */
export const getMyDocumentService = (tenantId:string):Promise<types.MyAwesomeData<Array<types.DocumentType>>> => {
  return httpRequest.get<Array<types.DocumentType>>(`${api.getDocList}?tenantId=${tenantId}`);
}

/**
 * @description: 删除文档
 * @date: 2025-07-12 11:31
 * @author wuwenqiang
 */
export const deleteMyDocumentService = (docId:string):Promise<types.MyAwesomeData<number>> => {
  return httpRequest.delete<number>(`${api.deleteDoc}${docId}`);
}

/**
 * @description: 获取目录列表
 * @date: 2025-07-26 20:21
 * @author wuwenqiang
 */
export const getDirectoryListService = (tenantId:string):Promise<types.MyAwesomeData<types.DirectoryType[]>> => {
  return httpRequest.get<types.DirectoryType[]>(`${api.getDirectoryList}?tenantId=${tenantId}`);
}

/**
 * @description: 创建目录
 * @date: 2025-07-27 12:42
 * @author wuwenqiang
 */
export const createDirectoryService = (directory:types.DirectoryType):Promise<types.MyAwesomeData<types.DirectoryType>> => {
  return httpRequest.post<types.DirectoryType>(api.createDir,directory);
}

/**
 * @description: 获取租户列表
 * @date: 2025-08-10 18:25
 * @author wuwenqiang
 */
export const getTenantListService = ():Promise<types.MyAwesomeData<types.TenantType[]>> => {
  return httpRequest.get<types.TenantType[]>(api.getUserTenantList);
}

/**
 * @description: 获取租户下的所有
 * @date: 2025-08-16 20:14
 * @author wuwenqiang
 */
export const getTenantUserListService = (tenantId:string,pageNum:number,pageSize:number):Promise<types.MyAwesomeData<types.TenantUserType[]>> => {
  return httpRequest.get<types.TenantUserType[]>(`${api.getTenantUserList}?tenantId=${tenantId}&pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 获取当前租户下当前用户的角色信息
 * @date: 2025-09-7 18:56
 * @author wuwenqiang
 */
export const getTenantUserService = (tenantId:string):Promise<types.MyAwesomeData<types.TenantUserType|null>> => {
  return httpRequest.get<types.TenantUserType|null>(`${api.getTenantUser}?tenantId=${tenantId}`);
}

/**
 * @description: 模糊搜索用户
 * @date: 2025-08-16 20:14
 * @author wuwenqiang
 */
export const searchUserListService = (keyword:string,tenantId:string,pageNum:number,pageSize:number):Promise<types.MyAwesomeData<types.UserWithChecked[]>> => {
  return httpRequest.get<types.UserWithChecked[]>(`${api.searchUsers}?keyword=${keyword}&tenantId=${tenantId}&pageNum=${pageNum}&pageSize=${pageSize}`);
}

/**
 * @description: 添加租户
 * @date: 2025-09-01 22:04
 * @author wuwenqiang
 */
export const addTenantUserService = (tenantId:string,userId:string):Promise<types.MyAwesomeData<types.TenantUserType>> => {
  return httpRequest.post<types.TenantUserType>(`${api.addTenantUser}${tenantId}/${userId}`);
}

/**
 * @description: 设置为管理员
 * @date: 2025-09-01 22:04
 * @author wuwenqiang
 */
export const addAdminService = (tenantId:string,userId:string):Promise<types.MyAwesomeData<types.TenantUserType>> => {
  const params:types.AdminParamsType = {tenantId,userId}
  return httpRequest.post<types.TenantUserType>(api.addAdmin,params);
}

/**
 * @description: 设置为管理员
 * @date: 2025-09-07 09:05
 * @author wuwenqiang
 */
export const deleteAdminService = (tenantId:string,userId:string):Promise<types.MyAwesomeData<types.TenantUserType>> => {
  const params:types.AdminParamsType = {tenantId,userId}
  return httpRequest.delete<types.TenantUserType>(api.deleteAdmin,params);
}

/**
 * @description: 删除租户
 * @date: 2025-09-20 14:33
 * @author wuwenqiang
 */
export const deleteTenantUserService = (tenantId:string,userId:string):Promise<types.MyAwesomeData<boolean>> => {
  return httpRequest.delete<boolean>(`${api.deleteTenantUser}/${tenantId}/${userId}`);
}
