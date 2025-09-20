export default {
  login: '/service/user/login', //登录
  getUserData: '/service/user-getway/getUserData', // 获取用户信息
  updateUser: '/service/user-getway/updateUser',//更新用户信息
  register: '/service/user/register',//注册
  vertifyUser: '/service/user/vertifyUser',// 校验账号是否存在
  sendEmailVertifyCode: '/service/user/sendEmailVertifyCode',// 找回密码
  resetPassword: '/service/user/resetPassword',// 重置密码
  updateAvater:'/service/user-getway/updateAvater',//更新头像
  updatePassword: '/service/user-getway/updatePassword',//更新密码
  loginByEmail: '/service/user/loginByEmail',//邮箱登录
  searchUsers: "/service/user-getway/searchUsers",// 搜索用户
  chat:"/service/chat/chat",// ai聊天
  getChatHistory: "/service/chat/getChatHistory",// ai聊天
  // chatWs: "/service/music/ws/chat",// ai聊天
  chatWs: "/service/chat/ws/chat",// ai聊天
  getModelList: "/service/chat/getModelList",// ai聊天
  uploadDoc: "/service/chat/uploadDoc",// 生成向量
  getDocList: "/service/chat/getDocList",// 查询我的文档
  deleteDoc: "/service/chat/deleteDoc/",// 删除我的文档
  getDirectoryList: "/service/chat/getDirectoryList",// 查询目录列表
  createDir: "/service/chat/createDir",// 创建目录
  renameDir: "/service/chat/renameDir",// 重命名目录
  deleteDir: "/service/chat/deleteDir/",// 删除目录
  getUserTenantList: "/service/tenant/getUserTenantList",// 获取用户当前的所有租户列表
  getTenantUserList: "/service/tenant/getTenantUserList",// 获取当前租户下的用户列表
  getTenantUser: "/service/tenant/getTenantUser",// 获取当前租户下当前用户角色信息
  addTenantUser:"/service/tenant/addTenantUser/",// 添加用户
  addAdmin:"/service/tenant/addAdmin",// 设置为管理员
  deleteAdmin:"/service/tenant/deleteAdmin",// 取消管理员
  deleteTenantUser: "/service/tenant/deleteTenantUser",// 删除用户
};
