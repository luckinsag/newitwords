<template>
  <div class="analysis-container">
    <v-card class="mb-4">
      <v-card-title class="text-h5 mb-4">データ分析</v-card-title>

      <v-card-text>
        <div class="mb-6">
          <div class="text-subtitle-1 mb-2">テスト成績推移</div>
          <div v-if="!loading" class="chart-container">
            <v-chart class="chart" :option="chartOption" autoresize />
          </div>
          <v-progress-circular
            v-else
            indeterminate
            color="primary"
          ></v-progress-circular>
        </div>
      </v-card-text>
    </v-card>
  </div>
</template>

<script>
import { useUserStore } from '@/store/user'
import { storeToRefs } from 'pinia'
import wordService from '@/api/wordService'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  GridComponent,
  ToolboxComponent,
  DataZoomComponent
} from 'echarts/components'
import VChart from 'vue-echarts'

// 注册 ECharts 组件
use([
  CanvasRenderer,
  LineChart,
  TitleComponent,
  TooltipComponent,
  GridComponent,
  ToolboxComponent,
  DataZoomComponent
])

export default {
  name: 'DataAnalysis',
  components: {
    VChart
  },
  setup() {
    const userStore = useUserStore()
    const { userId } = storeToRefs(userStore)
    return {
      userId
    }
  },
  data: () => ({
    loading: false,
    error: null,
    testScores: []
  }),
  computed: {
    chartOption() {
      // 按时间排序
      const sortedScores = [...this.testScores].sort((a, b) => 
        new Date(a.testTime) - new Date(b.testTime)
      )

      return {
        title: {
          text: 'テスト成績推移',
          left: 'center'
        },
        tooltip: {
          trigger: 'axis',
          formatter: (params) => {
            const data = params[0]
            return `第${data.dataIndex + 1}回テスト<br/>
                    日付: ${this.formatDate(sortedScores[data.dataIndex].testTime)}<br/>
                    点数: ${data.value}点`
          }
        },
        xAxis: {
          type: 'category',
          name: 'テスト回数',
          data: sortedScores.map((_, index) => `第${index + 1}回`),
          axisLabel: {
            interval: 0
          }
        },
        yAxis: {
          type: 'value',
          name: '点数',
          min: 0,
          max: 100
        },
        series: [
          {
            name: 'テスト成績',
            type: 'line',
            data: sortedScores.map(score => score.score),
            markPoint: {
              data: [
                { type: 'max', name: '最高点' },
                { type: 'min', name: '最低点' }
              ]
            },
            markLine: {
              data: [
                { type: 'average', name: '平均点' }
              ]
            }
          }
        ],
        toolbox: {
          feature: {
            saveAsImage: {},
            dataZoom: {
              yAxisIndex: 'none'
            },
            restore: {}
          }
        },
        dataZoom: [
          {
            type: 'slider',
            show: true,
            xAxisIndex: [0],
            start: 0,
            end: 100
          }
        ]
      }
    }
  },
  methods: {
    async fetchTestScores() {
      this.loading = true
      this.error = null
      try {
        const response = await wordService.getTestScores(this.userId)
        if (response && response.data) {
          this.testScores = response.data
        } else {
          this.testScores = []
        }
      } catch (error) {
        console.error('获取考试成绩失败:', error)
        this.error = error.response?.data?.message || '成績の取得に失敗しました'
        this.testScores = []
      } finally {
        this.loading = false
      }
    },
    formatDate(dateString) {
      if (!dateString) return ''
      // 将 "2025-06-09 01:40:48" 格式转换为 Date 对象
      const [datePart, timePart] = dateString.split(' ')
      const [year, month, day] = datePart.split('-')
      const [hours, minutes, seconds] = timePart.split(':')
      const date = new Date(year, month - 1, day, hours, minutes, seconds)
      return date.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
  },
  created() {
    this.fetchTestScores()
  }
}
</script>

<style scoped>
.analysis-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.chart-container {
  width: 100%;
  height: 400px;
}

.chart {
  width: 100%;
  height: 100%;
}
</style> 