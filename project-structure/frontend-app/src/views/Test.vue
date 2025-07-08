<template>
  <div>
    <!-- 顶部操作栏 -->
    <v-card class="mb-4">
      <v-card-text>
        <div class="d-flex align-center">
          <div class="d-flex align-center mr-4">
            <v-select
              v-model="lessonRange.start"
              :items="lessonOptions"
              label=""
              density="compact"
              hide-details
              style="width: 150px;"
              class="mr-4"
            ></v-select>
            <span class="mr-4">～</span>
            <v-select
              v-model="lessonRange.end"
              :items="lessonOptions"
              label=""
              density="compact"
              hide-details
              style="width: 150px;"
            ></v-select>
          </div>
          
          <v-btn
            color="primary"
            variant="text"
            class="mr-4"
            @click="showAllLessons"
          >
            全部
          </v-btn>

          <v-btn
            color="secondary"
            variant="text"
            class="mr-4"
            @click="startTest"
            :disabled="!canStartTest"
          >
            テスト開始
          </v-btn>
          <!-- prepend-icon="mdi-exit-to-app" -->
          <v-btn
            color="secondary"
            variant="text"
            class="mr-4"
            @click="exitTest"
          >
            テストを終了
          </v-btn>
        </div>
      </v-card-text>
    </v-card>

    <!-- 考试区域 -->
    <v-card v-if="isTestStarted">
      <v-card-text>
        <!-- 进度显示 -->
        <div class="d-flex justify-space-between align-center mb-4">
          <div class="text-h6">
            問題 {{ currentQuestionIndex + 1 }}/10
          </div>
          <div class="text-h6">
            正解: {{ correctCount }}
          </div>
        </div>

        <!-- 题目显示 -->
        <div v-if="currentQuestion" class="text-center mb-6">
          <div class="text-h5 mb-4">{{ currentQuestion.chinese }}</div>
          <v-text-field
            v-model="userAnswer"
            label="日本語を入力"
            variant="outlined"
            density="comfortable"
            hide-details
            class="mx-auto"
            style="max-width: 400px;"
            @keyup.enter="checkAnswer"
          ></v-text-field>
        </div>

        <!-- 答案反馈 -->
        <div v-if="showFeedback" class="text-center">
          <div :class="isCorrect ? 'text-success' : 'text-error'" class="text-h6 mb-2">
            {{ isCorrect ? '正解！' : '不正解' }}
          </div>
          <div v-if="!isCorrect && showCorrectAnswer" class="text-body-1 mb-4">
            正解: {{ currentQuestion.japanese }}
          </div>
          <v-btn
            v-if="!isCorrect"
            color="primary"
            @click="showCorrectAnswer = true"
            class="mr-2"
          >
            答えを見る
          </v-btn>
          <v-btn
            v-if="!isCorrect || showCorrectAnswer"
            color="primary"
            @click="nextQuestion"
          >
            {{ isLastQuestion ? '結果を見る' : '次の問題' }}
          </v-btn>
        </div>
      </v-card-text>
    </v-card>

    <!-- 结果页面 -->
    <v-card v-if="showResults">
      <v-card-text>
        <div class="text-center">
          <div class="text-h4 mb-4">テスト結果</div>
          <div class="text-h5 mb-6">
            正解率: {{ (correctCount / 10 * 100).toFixed(1) }}%
          </div>
          
          <!-- 答题记录 -->
          <div class="test-results mb-6">
            <!-- 表头 -->
            <div class="result-header mb-2">
              <div class="d-flex align-center justify-center">
                <span class="question-number mr-2">No.</span>
                <span class="chinese-text mr-4">中国語</span>
                <span class="japanese-text mr-4">正解</span>
                <span class="user-answer-text mr-4">あなたの答え</span>
                <span class="result-icon">結果</span>
              </div>
            </div>
            <!-- 答题记录列表 -->
            <div v-for="(word, index) in testWords" :key="index" class="result-item mb-2">
              <div class="d-flex align-center justify-center">
                <span class="question-number mr-2">{{ index + 1 }}.</span>
                <span class="chinese-text mr-4">{{ word.chinese }}</span>
                <span class="japanese-text mr-4">{{ word.japanese }}</span>
                <span class="user-answer-text mr-4" :class="{'text-error': userAnswers[index] !== word.japanese.replace(/[（(].*?[)）]/g, '').trim()}">
                  {{ userAnswers[index] || '未回答' }}
                </span>
                <v-icon
                  :color="userAnswers[index] === word.japanese.replace(/[（(].*?[)）]/g, '').trim() ? 'success' : 'error'"
                  size="small"
                >
                  {{ userAnswers[index] === word.japanese.replace(/[（(].*?[)）]/g, '').trim() ? 'mdi-check-circle' : 'mdi-close-circle' }}
                </v-icon>
              </div>
            </div>
          </div>

          <v-btn
            color="primary"
            @click="resetTest"
          >
            もう一度
          </v-btn>
        </div>
      </v-card-text>
    </v-card>
  </div>
</template>

<script>
import wordService from '@/api/wordService'
import { useUserStore } from '@/store/user'

export default {
  name: 'Test',
  setup() {
    const userStore = useUserStore();
    return {
      userStore
    };
  },
  data: () => ({
    lessonRange: {
      start: '1',
      end: '31'
    },
    lessonOptions: Array.from({ length: 31 }, (_, i) => ({
      title: `Lesson ${i + 1}`,
      value: String(i + 1)
    })),
    words: [],
    testWords: [],
    currentQuestionIndex: 0,
    userAnswer: '',
    userAnswers: [], // 存储用户的所有答案
    showFeedback: false,
    showCorrectAnswer: false,
    isCorrect: false,
    correctCount: 0,
    isTestStarted: false,
    showResults: false
  }),
  computed: {
    currentQuestion() {
      return this.testWords[this.currentQuestionIndex]
    },
    isLastQuestion() {
      return this.currentQuestionIndex === 9
    },
    canStartTest() {
      console.log('Words length:', this.words.length)
      return this.words && this.words.length >= 10
    }
  },
  watch: {
    lessonRange: {
      handler() {
        this.fetchWords()
      },
      deep: true
    }
  },
  created() {
    this.fetchWords()
  },
  methods: {
    async fetchWords() {
      try {
        let response
        if (this.lessonRange.start === '1' && this.lessonRange.end === '31') {
          response = await wordService.getAllWords()
        } else {
          response = await wordService.getWordsByCategories(
            this.lessonRange.start,
            this.lessonRange.end
          )
        }
        console.log('Words response:', response)
        if (response && response.data) {
          this.words = response.data.data || response.data
          console.log('Fetched words:', this.words)
        }
      } catch (error) {
        console.error('Error fetching words:', error)
      }
    },
    showAllLessons() {
      this.lessonRange = {
        start: '1',
        end: '31'
      }
    },
    startTest() {
      console.log('Starting test with words:', this.words)
      if (!this.words || this.words.length < 10) {
        console.error('Not enough words available:', this.words?.length)
        return
      }
      // 随机选择10个单词
      this.testWords = this.getRandomWords(10)
      console.log('Selected test words:', this.testWords)
      this.currentQuestionIndex = 0
      this.correctCount = 0
      this.userAnswers = [] // 重置用户答案
      this.isTestStarted = true
      this.showResults = false
      this.userAnswer = ''
      this.showFeedback = false
    },
    getRandomWords(count) {
      if (!this.words || this.words.length === 0) {
        console.error('No words available for test')
        return []
      }
      const shuffled = [...this.words].sort(() => 0.5 - Math.random())
      return shuffled.slice(0, count)
    },
    checkAnswer() {
      if (!this.userAnswer.trim()) return
      
      // 移除括号内的读音和所有空格后再比较
      const cleanAnswer = this.userAnswer.trim()
        .replace(/[（(].*?[)）]/g, '') // 移除括号内容
        .replace(/\s+/g, '') // 移除所有空格
        .trim()
      
      const cleanCorrect = this.currentQuestion.japanese
        .replace(/[（(].*?[)）]/g, '') // 移除括号内容
        .replace(/\s+/g, '') // 移除所有空格
        .trim()
      
      this.isCorrect = cleanAnswer === cleanCorrect
      // 保存用户答案
      this.userAnswers[this.currentQuestionIndex] = this.userAnswer.trim()
      
      if (this.isCorrect) {
        this.correctCount++
        // 答案正确时，显示反馈后自动进入下一题
        this.showFeedback = true
        setTimeout(() => {
          this.nextQuestion()
        }, 1000) // 1秒后自动进入下一题
      } else {
        this.showFeedback = true
        this.showCorrectAnswer = false
      }
    },
    nextQuestion() {
      if (this.isLastQuestion) {
        this.showResults = true
        this.isTestStarted = false
        // 保存考试记录
        this.saveTestRecord()
      } else {
        this.currentQuestionIndex++
        this.userAnswer = ''
        this.showFeedback = false
        this.showCorrectAnswer = false
      }
    },
    async saveTestRecord() {
      try {
        const userTestDTO = {
          userId: Number(this.userStore.userId), // 确保是数字类型
          endAt: new Date().toISOString(),        // 转换为 ISO 字符串格式
          score: Number(this.correctCount * 10)   // 确保是数字类型
        }
        console.log('准备保存考试记录:', userTestDTO);
        const response = await wordService.saveUserTest(userTestDTO)
        console.log('考试记录保存成功，考试编号:', response.data)
        
        // 询问用户是否保存错题
        const shouldSaveWrongWords = await this.$dialog.confirm({
          title: '错题保存',
          text: '是否将答错的题目保存到错题本？',
          confirmText: '保存',
          cancelText: '不保存'
        })
        
        if (shouldSaveWrongWords) {
          await this.saveWrongWords(response.data)
          this.$toast.success('错题已保存到错题本')
        }
      } catch (error) {
        console.error('保存考试记录失败:', error)
        // 添加错误提示
        this.$toast.error('保存考试记录失败，请稍后重试')
      }
    },
    // 保存错题
    async saveWrongWords(sessionId) {
      try {
        // 遍历所有题目，找出答错的题目
        for (let i = 0; i < this.testWords.length; i++) {
          const word = this.testWords[i]

           // ⚠️ 添加这两行日志来检查 word 对象的实际内容
          console.log(`Debug: word object at index ${i}:`, word);
          console.log(`Debug: word.id at index ${i}:`, word.id);

          const userAnswer = this.userAnswers[i]
          const correctAnswer = word.japanese.replace(/[（(].*?[)）]/g, '').trim()
          
          // 如果答案不正确，添加到错题本
          if (userAnswer !== correctAnswer) {
            const userWrongDTO = {
              sessionId: Number(sessionId),
              wordId: Number(word.wordId),
              userId: Number(this.userStore.userId)
            }
            console.log('准备添加错题:', userWrongDTO)
            await wordService.insertWrong(userWrongDTO)
          }
        }
        console.log('错题保存完成')
      } catch (error) {
        console.error('保存错题失败:', error)
        this.$toast.error('保存错题失败，请稍后重试')
        throw error // 向上传递错误，让调用者知道保存失败
      }
    },
    resetTest() {
      this.isTestStarted = false
      this.showResults = false
      this.currentQuestionIndex = 0
      this.correctCount = 0
      this.userAnswers = [] // 重置用户答案
      this.userAnswer = ''
      this.showFeedback = false
      this.showCorrectAnswer = false
    },
    exitTest() {
      this.$router.push('/')
    }
  }
}
</script>

<style scoped>
.v-card {
  margin-bottom: 20px;
}

.test-results {
  max-width: 800px;
  margin: 0 auto;
}

.result-header {
  padding: 8px;
  background-color: #e0e0e0;
  border-radius: 4px;
  font-weight: bold;
}

.result-item {
  padding: 8px;
  border-radius: 4px;
  background-color: #f5f5f5;
}

.question-number {
  min-width: 40px;
  font-weight: bold;
}

.chinese-text {
  min-width: 120px;
}

.japanese-text {
  min-width: 180px;
}

.user-answer-text {
  min-width: 180px;
}

.result-icon {
  min-width: 40px;
  text-align: center;
}

.text-error {
  color: #ff5252;
}

/* 添加新的样式 */
.v-card-text {
  padding: 24px;
}

.d-flex {
  padding: 0 16px;
}
</style> 