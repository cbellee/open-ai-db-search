import React from 'react';
import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import ShowMoreText from "react-show-more-text";
import { Card, CardContent, Typography, CardActions, CardHeader, CardMedia, Avatar, IconButton, Collapse, ListItem, List } from '@mui/material';
import { Favorite, Share, ColorLens } from '@mui/icons-material'

var imageData = {
  images: [
    {
      "image": "watch-1.jpg"
    },
    {
      "image": "watch-2.jpg"
    },
    {
      "image": "outdoor-1.jpg"
    },
    {
      "image": "rope-1.jpg"
    },
    {
      "image": "headphones-1.jpg"
    }
  ]
}

function DataCard({ item, index }) {
  const executeOnClick = (isExpanded) => {
    console.log(isExpanded);
  }

  return (
    <div class="flex flex-row">
      <Card class="shadow m-0 max-w-96 min-w-60 bg-white ">
        <CardHeader
          /*   avatar={
              <ColorLens fontSize="large" sx={{ color: item.color }} aria-label="recipe">
              </ColorLens>
            } */
          sx={{ minHeight: 120 }}
          title={item.name}
          subheader={item.brand}
        />
        <CardMedia
          component="img"
          image={imageData.images[index].image}
          alt="Product Image"
          sx={{ padding: "0 0 0 0", minHeight: 210, objectFit: "fill" }}
        />
        <CardContent>
          <Typography variant="body3" color="text.secondary" class="text-pretty">
            <ShowMoreText
              /* Default options */
              lines={8}
              more="Read more"
              less="Read less"

              onClick={executeOnClick}
              expanded={false}
              truncatedEndingComponent={"... "}
            >
              {item.description}
            </ShowMoreText>
          </Typography>
        </CardContent>
        <CardContent>
          <List>
            <ListItem>
              <Typography variant="body2" color="text.secondary">
                Price: ${item.price}
              </Typography>
            </ListItem>
            <ListItem sx={{ padding: 0, margin: 0 }}>
              <Typography variant="body2" color="text.secondary">
                Type: {item.type}
              </Typography>
            </ListItem>
          </List>
        </CardContent>
        <CardActions disableSpacing>
          <IconButton aria-label="add to favorites">
            <Favorite />
          </IconButton>
          <IconButton aria-label="share">
            <Share />
          </IconButton>
        </CardActions>
      </Card>
    </div>
  )
}

export default function DataCardGrid({ data }) {
  const headers = Object.keys(data[0]);
  const rows = data.map(item => Object.values(item));

  return (
    <Box sx={{ flexGrow: 1 }}>
      <Grid container spacing={{ xs: 1, md: 3 }} columns={{ xs: 4, sm: 8, md: 16 }}>
        {data.map((row, index) => (
          <Grid item xs={2} sm={4} md={4} key={index}>
            <DataCard key={index} item={row} index={index}></DataCard>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
}
