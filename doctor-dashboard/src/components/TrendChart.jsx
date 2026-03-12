import { Line } from "react-chartjs-2";

const TrendChart = ({ records }) => {

  const metricRecords = (records || []).filter(
    (r) => Array.isArray(r.metrics) && r.metrics.length > 0
  )

  if(metricRecords.length === 0){
    return null
  }

  const heartRates = metricRecords.map(r=>({
    date:r.timestamp,
    value:r.metrics[0]?.value
  })).filter((r) => r.value !== undefined && r.value !== null)

  if(heartRates.length === 0){
    return null
  }

  const chartData = {
    labels: heartRates.map(r=>r.date),
    datasets:[
      {
        label:"Heart Rate",
        data: heartRates.map(r=>r.value),
        borderColor:"red"
      }
    ]
  }

  return (
    <div style={{marginTop:"30px"}}>
      <h3>Heart Rate Trend</h3>
      <Line data={chartData}/>
    </div>
  )
}

export default TrendChart
