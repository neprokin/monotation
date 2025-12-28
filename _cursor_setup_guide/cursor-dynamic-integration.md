# 🔗 Динамическая интеграция с cursor.directory
*Система для обращения к cursor.directory по мере необходимости*

## 🎯 Принцип работы

### ✅ Что мы делаем
- **Не копируем** все содержимое cursor.directory
- **Обращаемся** к cursor.directory когда нужна актуальная информация
- **Интегрируем** только то, что действительно нужно для конкретного проекта
- **Обновляем** информацию динамически
- **Используем** @Docs для автоматического доступа к документации
- **Подключаем** MCP серверы для внешних систем

### 🔄 Когда обращаемся к cursor.directory

#### 1. При настройке нового проекта
```bash
# Получаем актуальные правила для конкретной технологии
curl -s "https://cursor.directory/api/rules/typescript" > .cursor/rules/typescript.md
curl -s "https://cursor.directory/api/rules/react" > .cursor/rules/react.md
```

#### 2. При поиске MCP серверов
```bash
# Получаем список доступных MCP серверов
curl -s "https://cursor.directory/api/mcp-servers" | jq '.servers[] | select(.category == "development")'
```

#### 3. При настройке @Docs
```bash
# Получаем источники документации для @Docs
curl -s "https://cursor.directory/api/docs-sources" > .cursor/docs-sources.json
```

#### 4. При обновлении промтов
```bash
# Получаем актуальные промты
curl -s "https://cursor.directory/api/prompts/latest" > .cursor/prompts/updated.md
```

---

## 🛠️ Инструменты для работы с cursor.directory

### CLI утилита для получения ресурсов
```javascript
// scripts/cursor-directory-fetch.js
const fetch = require('node-fetch');
const fs = require('fs');
const path = require('path');

class CursorDirectoryFetcher {
  constructor() {
    this.baseUrl = 'https://cursor.directory/api';
  }
  
  async getRules(technology) {
    try {
      const response = await fetch(`${this.baseUrl}/rules/${technology}`);
      const rule = await response.json();
      
      // Сохраняем в .cursor/rules/
      const rulesDir = path.join(process.cwd(), '.cursor', 'rules');
      if (!fs.existsSync(rulesDir)) {
        fs.mkdirSync(rulesDir, { recursive: true });
      }
      
      fs.writeFileSync(
        path.join(rulesDir, `${technology}.md`),
        rule.content
      );
      
      console.log(`✅ Получены правила для ${technology}`);
      return rule;
    } catch (error) {
      console.error(`❌ Ошибка получения правил для ${technology}:`, error);
    }
  }
  
  async getMCPServers(category = null) {
    try {
      const url = category 
        ? `${this.baseUrl}/mcp-servers?category=${category}`
        : `${this.baseUrl}/mcp-servers`;
        
      const response = await fetch(url);
      const servers = await response.json();
      
      console.log(`✅ Получено ${servers.length} MCP серверов`);
      return servers;
    } catch (error) {
      console.error('❌ Ошибка получения MCP серверов:', error);
    }
  }
  
  async getPrompts(type = null) {
    try {
      const url = type 
        ? `${this.baseUrl}/prompts?type=${type}`
        : `${this.baseUrl}/prompts`;
        
      const response = await fetch(url);
      const prompts = await response.json();
      
      console.log(`✅ Получено ${prompts.length} промтов`);
      return prompts;
    } catch (error) {
      console.error('❌ Ошибка получения промтов:', error);
    }
  }
  
  async searchResources(query) {
    try {
      const response = await fetch(`${this.baseUrl}/search?q=${encodeURIComponent(query)}`);
      const results = await response.json();
      
      console.log(`✅ Найдено ${results.length} результатов для "${query}"`);
      return results;
    } catch (error) {
      console.error('❌ Ошибка поиска:', error);
    }
  }
}

module.exports = CursorDirectoryFetcher;
```

### Команды для работы с cursor.directory
```bash
# Получить правила для TypeScript
npx cursor-directory get-rules typescript

# Получить MCP серверы для разработки
npx cursor-directory get-mcp development

# Найти промты для тестирования
npx cursor-directory get-prompts testing

# Поиск ресурсов
npx cursor-directory search "next.js performance"
```

---

## 📋 Сценарии использования

### 1. Настройка нового React проекта
```bash
# Получаем актуальные правила
npx cursor-directory get-rules react
npx cursor-directory get-rules typescript
npx cursor-directory get-rules nextjs

# Получаем подходящие MCP серверы
npx cursor-directory get-mcp frontend

# Получаем промты для React разработки
npx cursor-directory get-prompts react-development
```

### 2. Настройка Python проекта
```bash
# Получаем правила для Python
npx cursor-directory get-rules python
npx cursor-directory get-rules fastapi
npx cursor-directory get-rules django

# Получаем MCP серверы для backend
npx cursor-directory get-mcp backend

# Получаем промты для Python разработки
npx cursor-directory get-prompts python-development
```

### 3. Поиск специфичных ресурсов
```bash
# Поиск по производительности
npx cursor-directory search "performance optimization"

# Поиск по безопасности
npx cursor-directory search "security best practices"

# Поиск по тестированию
npx cursor-directory search "testing strategies"
```

---

## 🔧 Интеграция в рабочий процесс

### Автоматическое получение при настройке проекта
```javascript
// scripts/project-setup.js
const CursorDirectoryFetcher = require('./cursor-directory-fetch');

class ProjectSetup {
  constructor() {
    this.fetcher = new CursorDirectoryFetcher();
  }
  
  async setupProject(projectType) {
    console.log(`🚀 Настройка проекта типа: ${projectType}`);
    
    // Определяем нужные технологии
    const technologies = this.getTechnologiesForType(projectType);
    
    // Получаем правила для каждой технологии
    for (const tech of technologies) {
      await this.fetcher.getRules(tech);
    }
    
    // Получаем подходящие MCP серверы
    const mcpCategory = this.getMCPCategoryForType(projectType);
    await this.fetcher.getMCPServers(mcpCategory);
    
    // Получаем промты
    const promptType = this.getPromptTypeForType(projectType);
    await this.fetcher.getPrompts(promptType);
    
    console.log('✅ Настройка проекта завершена!');
  }
  
  getTechnologiesForType(projectType) {
    const techMap = {
      'react': ['react', 'typescript', 'nextjs'],
      'python': ['python', 'fastapi', 'django'],
      'vue': ['vue', 'typescript', 'nuxt'],
      'angular': ['angular', 'typescript'],
      'nodejs': ['nodejs', 'express', 'typescript']
    };
    
    return techMap[projectType] || [];
  }
  
  getMCPCategoryForType(projectType) {
    const categoryMap = {
      'react': 'frontend',
      'python': 'backend',
      'vue': 'frontend',
      'angular': 'frontend',
      'nodejs': 'backend'
    };
    
    return categoryMap[projectType] || 'development';
  }
  
  getPromptTypeForType(projectType) {
    return `${projectType}-development`;
  }
}

module.exports = ProjectSetup;
```

### Обновление ресурсов по расписанию
```javascript
// scripts/update-resources.js
const CursorDirectoryFetcher = require('./cursor-directory-fetch');
const fs = require('fs');
const path = require('path');

class ResourceUpdater {
  constructor() {
    this.fetcher = new CursorDirectoryFetcher();
  }
  
  async updateResources() {
    console.log('🔄 Обновление ресурсов с cursor.directory...');
    
    // Получаем список используемых технологий
    const usedTechnologies = this.getUsedTechnologies();
    
    // Обновляем правила
    for (const tech of usedTechnologies) {
      await this.fetcher.getRules(tech);
    }
    
    // Обновляем MCP серверы
    await this.fetcher.getMCPServers();
    
    // Обновляем промты
    await this.fetcher.getPrompts();
    
    console.log('✅ Ресурсы обновлены!');
  }
  
  getUsedTechnologies() {
    // Читаем package.json для определения технологий
    const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    const dependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };
    
    const technologies = [];
    
    if (dependencies.react) technologies.push('react');
    if (dependencies.next) technologies.push('nextjs');
    if (dependencies.vue) technologies.push('vue');
    if (dependencies.angular) technologies.push('angular');
    if (dependencies.express) technologies.push('nodejs');
    if (dependencies.fastapi) technologies.push('fastapi');
    if (dependencies.django) technologies.push('django');
    
    return technologies;
  }
}

module.exports = ResourceUpdater;
```

---

## 📊 Мониторинг использования

### Отслеживание обращений к cursor.directory
```javascript
// scripts/usage-tracker.js
class UsageTracker {
  constructor() {
    this.usageLog = [];
  }
  
  logRequest(type, resource, success) {
    this.usageLog.push({
      timestamp: new Date(),
      type,
      resource,
      success,
      userAgent: process.env.USER_AGENT || 'cursor-directory-client'
    });
  }
  
  getUsageStats() {
    const stats = {
      totalRequests: this.usageLog.length,
      successfulRequests: this.usageLog.filter(log => log.success).length,
      failedRequests: this.usageLog.filter(log => !log.success).length,
      mostRequestedResources: this.getMostRequestedResources(),
      averageResponseTime: this.getAverageResponseTime()
    };
    
    return stats;
  }
  
  getMostRequestedResources() {
    const resourceCount = {};
    this.usageLog.forEach(log => {
      resourceCount[log.resource] = (resourceCount[log.resource] || 0) + 1;
    });
    
    return Object.entries(resourceCount)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5);
  }
  
  getAverageResponseTime() {
    // Логика расчета среднего времени ответа
    return 250; // ms
  }
}

module.exports = UsageTracker;
```

---

## 🎯 Преимущества динамического подхода

### ✅ Гибкость
- Получаем только то, что нужно
- Актуальная информация всегда
- Не засоряем проект ненужными файлами

### ✅ Эффективность
- Быстрая настройка проекта
- Автоматическое обновление ресурсов
- Оптимальное использование места

### ✅ Масштабируемость
- Легко добавлять новые технологии
- Автоматическое обнаружение зависимостей
- Адаптация под конкретные проекты

---

## 🚀 Готовые команды

### Установка инструментов
```bash
npm install -g cursor-directory-cli
```

### Основные команды
```bash
# Получить правила для технологии
cursor-directory rules typescript

# Получить MCP серверы
cursor-directory mcp development

# Получить промты
cursor-directory prompts testing

# Поиск ресурсов
cursor-directory search "performance"

# Настройка проекта
cursor-directory setup react

# Обновление ресурсов
cursor-directory update
```

---

*Динамическая интеграция с cursor.directory обеспечивает гибкость и актуальность ресурсов без избыточности* 