import { Line } from "react-chartjs-2";

const TrendChart = ({ records }) => {

  if(!records || records.length === 0){
    return null
  }

  const heartRates = records.map(r=>({
    date:r.timestamp,
    value:r.metrics[0]?.value
  }))

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