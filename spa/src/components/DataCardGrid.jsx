import React from 'react';
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import DataCard from './DataCard';

export default function DataCardGrid({ data }) {
  const headers = Object.keys(data[0]);
  const rows = data.map(item => Object.values(item));

  return (
    <Box sx={{ flexGrow: 1 }}>
      <Grid container spacing={{ xs: 1, md: 3 }} columns={{ xs: 4, sm: 8, md: 20 }}>
        {data.map((row, index) => (
          <Grid item xs={1} sm={3} md={4} key={index}>
            <DataCard key={index} item={row} index={index}></DataCard>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
}
