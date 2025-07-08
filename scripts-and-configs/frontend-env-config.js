// 前端环境配置 - 生产部署时需要修改API地址
// 运行此脚本来更新API配置: node frontend-env-config.js

const fs = require('fs');
const path = require('path');

// 配置你的生产环境API地址
const PRODUCTION_API_URL = 'https://your-ec2-public-ip:8080'; // 替换为你的EC2公网IP或域名
const FRONTEND_DIR = 'IT-wordslearing_display3.0 2';

// 文件路径
const userServicePath = path.join(FRONTEND_DIR, 'src/api/userService.js');
const wordServicePath = path.join(FRONTEND_DIR, 'src/api/wordService.js');

console.log('=== 更新前端API配置 ===');

// 更新 userService.js
if (fs.existsSync(userServicePath)) {
    let userServiceContent = fs.readFileSync(userServicePath, 'utf8');
    
    // 替换 baseURL
    userServiceContent = userServiceContent.replace(
        /baseURL:\s*['"]http:\/\/localhost:8080['"]/,
        `baseURL: '${PRODUCTION_API_URL}'`
    );
    
    fs.writeFileSync(userServicePath, userServiceContent);
    console.log('✅ 已更新 userService.js');
} else {
    console.log('❌ 找不到 userService.js 文件');
}

// 更新 wordService.js  
if (fs.existsSync(wordServicePath)) {
    let wordServiceContent = fs.readFileSync(wordServicePath, 'utf8');
    
    // 替换 baseURL (从相对路径改为完整URL)
    wordServiceContent = wordServiceContent.replace(
        /baseURL:\s*['"]\/api['"]/,
        `baseURL: '${PRODUCTION_API_URL}/api'`
    );
    
    fs.writeFileSync(wordServicePath, wordServiceContent);
    console.log('✅ 已更新 wordService.js');
} else {
    console.log('❌ 找不到 wordService.js 文件');
}

console.log(`=== 配置完成 ===`);
console.log(`API地址已更新为: ${PRODUCTION_API_URL}`);
console.log('现在可以运行构建命令: npm run build'); 