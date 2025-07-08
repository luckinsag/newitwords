// API配置文件
const config = {
  development: {
    baseURL: 'http://localhost:8080',
    timeout: 5000
  },
  production: {
    baseURL: window.location.protocol + '//' + window.location.hostname + ':8080',
    timeout: 10000
  },
  docker: {
    baseURL: 'http://backend:8080',
    timeout: 10000
  }
}

// 获取当前环境
const getEnvironment = () => {
  if (process.env.NODE_ENV === 'production') {
    return 'production'
  } else if (process.env.VUE_APP_ENV === 'docker') {
    return 'docker'
  } else {
    return 'development'
  }
}

// 导出当前环境的配置
const currentEnv = getEnvironment()
export default config[currentEnv] 