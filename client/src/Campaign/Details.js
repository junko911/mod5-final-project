import React, { useState } from 'react'
import Preview from './Preview'
import { Alert } from 'reactstrap'
import moment from 'moment'

const Details = ({ campaign }) => {

  const [alert, setAlert] = useState(false)
  const toggle = () => setAlert(!alert)

  const alertDisplay = alert ? "block" : "none"

  return (
    <>
      {campaign ?
        <>
          <Alert color="success" style={{ display: alertDisplay }}>
            The campaign has been sent!
          </Alert>
          <h1>Campaign Details</h1>
          <h4>Name: {campaign.name}</h4>
          <h4>Segment: {campaign.segment.name}</h4>
          <h4>Status: {campaign.status[0].toUpperCase() + campaign.status.slice(1)}</h4>
          <h4>Created at: {moment(campaign.created_at).calendar()}</h4>
          <Preview id={campaign.id} toggleAlert={toggle} />
        </>
        : null}
    </>
  )
}

export default Details