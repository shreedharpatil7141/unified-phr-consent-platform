const ConsentInfo = ({ consent }) => {

  if(!consent) return null

  return (
    <div style={{
      background:"white",
      padding:"20px",
      borderRadius:"10px"
    }}>

      <h3>Consent Information</h3>

      <p><strong>Category:</strong> {consent.categories}</p>
      <p><strong>Date Range:</strong> {consent.date_from} → {consent.date_to}</p>
      <p><strong>Expires:</strong> {consent.expires_at}</p>

    </div>
  )
}

export default ConsentInfo