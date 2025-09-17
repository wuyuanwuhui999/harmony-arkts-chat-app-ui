import { HOST } from '../common/constant';
export const zerofull = (value: number): string | number => {
  return value < 10 ? "0" + value : value + ''
}

export const formatTime = (value: string | number): string => {
  const date = new Date(typeof value === 'string' ? value.replace(/T/, ' ') : value);
  const nowDate = new Date()
  let diff = Math.ceil((nowDate.getTime() - date.getTime()) / 1000);
  if (diff < 60) {
    return "刚刚";
  } else if (diff < 60 * 60) {
    return Math.ceil(diff / 60) + "分前";
  } else if (diff < 60 * 60 * 24) {
    return Math.ceil(diff / (60 * 60)) + "小时前";
  } else if (diff < 60 * 60 * 24 * 30) {
    return Math.ceil(diff / (60 * 60 * 24)) + "天前";
  } else if (diff < 60 * 60 * 24 * 30 * 12) {
    return Math.ceil(diff / (60 * 60 * 24 * 30)) + "个月前";
  }
  const year = zerofull(date.getFullYear());
  const month = zerofull(date.getMonth() + 1);
  const dates = zerofull(date.getDate());
  const hour = zerofull(date.getHours());
  const minutes = zerofull(date.getMinutes());
  const seconds = zerofull(date.getSeconds());
  return `${year}-${month}-${dates} ${hour}:${minutes}:${seconds}`
};

export const formatSecond = (value: number, showHour: boolean = false): string => {
  if (showHour) {
    return `${zerofull(Math.floor(value / (60 * 60)))}:${zerofull(Math.floor(value % (60 * 60) /
      60))}:${zerofull(Math.floor(value % (60 * 60) % 60))}`
  } else {
    return `${zerofull(Math.floor(value / 60))}:${zerofull(Math.floor(value % 60))}`
  }
};

export const getMusicCover =
  (cover: string = "") => /http[s]?:\/\//.test(cover) ? cover.replace('{size}', '480') : HOST + cover

export const strictEmailRegex = /^[a-zA-Z0-9]+([._%+-][a-zA-Z0-9]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}$/;


// 生成32位随机十六进制字符串
export const  generateSecureID = () :string => {
  // 创建 32 位 Uint8Array
  const buffer = new Uint8Array(16);

  // 使用时间戳+随机数增强随机性
  const seed = Date.now() ^ (Math.random() * 0xFFFFFFFF);
  let state = Math.floor(seed);

  // 改进的伪随机生成器
  for (let i = 0; i < buffer.length; i++) {
    // Xorshift 算法增强随机性
    state ^= (state << 13);
    state ^= (state >>> 17);
    state ^= (state << 5);
    buffer[i] = state & 0xFF;
  }

  // 转换为十六进制
  let hexId = '';
  for (let i = 0; i < buffer.length; i++) {
    hexId += buffer[i].toString(16).padStart(2, '0');
  }

  return hexId;
}

export const formatTimeAgo = (createTime:string)=> {
  // 获取当前时间和目标时间
  const now = new Date()
  const targetDate = new Date(createTime)

  // 计算时间差（毫秒）
  const diff = now.getTime() - targetDate.getTime();

  // 处理未来时间
  if (diff < 0) return '刚刚'

  // 计算各时间单位
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  // 计算精确的月份和年份差
  const targetYear = targetDate.getFullYear()
  const targetMonth = targetDate.getMonth()
  const targetDay = targetDate.getDate()
  const nowYear = now.getFullYear()
  const nowMonth = now.getMonth()
  const nowDay = now.getDate()

  let monthsDiff = (nowYear - targetYear) * 12 + (nowMonth - targetMonth)
  if (nowDay < targetDay) monthsDiff--

  let yearsDiff = nowYear - targetYear
  if (nowMonth < targetMonth || (nowMonth === targetMonth && nowDay < targetDay)) {
    yearsDiff--
  }

  // 判断并返回结果
  if (seconds < 60) {
    return '刚刚'
  } else if (minutes < 60) {
    return `${minutes}分钟前`
  } else if (hours < 24) {
    return `${hours}小时前`
  } else if (days <= 31) {
    return `${days}天前`
  } else if (monthsDiff < 12) {
    return `${monthsDiff}个月前`
  } else {
    return `${yearsDiff}年前`
  }
}
