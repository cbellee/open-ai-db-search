import React from 'react';
import ShowMoreText from "react-show-more-text";
import { Card, CardContent, Typography, CardActions, CardHeader, CardMedia, Avatar, IconButton, Collapse, ListItem, List } from '@mui/material';
import { Favorite, Share } from '@mui/icons-material'

export default function DataCard({ item, index }) {
    var imageData = {
        images: [
            {
                "image": "images/watch-1.jpg"
            },
            {
                "image": "images/watch-2.jpg"
            },
            {
                "image": "images/outdoor-1.jpg"
            },
            {
                "image": "images/rope-1.jpg"
            },
            {
                "image": "images/headphones-1.jpg"
            },
            {
                "image": "images/climbing-1.jpg"
            }
        ]
    }

    const executeOnClick = (isExpanded) => {
    }

    function randomNumberInRange(min, max) {
        return Math.floor(Math.random()
            * (max - min + 1)) + min;
    };

    return (
        <Card class="m-0 max-w-72 bg-white rounded-md shadow-md">
            <CardHeader
                class="min-h-32 p-5 text-white bg-slate-800 rounded-t-md"
                title={item.name}
                titleTypographyProps={{ variant: 'h5' }}
                subheaderTypographyProps={{ color: 'antiquewhite' }}
                subheader={item.brand}
            />
            <CardMedia
                component="img"
                image={imageData.images[randomNumberInRange(0, 5)].image}
                alt="Product Image"
                class="object-scale-down"
                sx={{ padding: "0 0 0 0", margin: "0 0 0 0", minHeight: 0, objectFit: "fill" }}
            />
            <CardContent>
                <Typography variant="body3" color="text.secondary" class="text-pretty font-light">
                    <ShowMoreText
                        lines={4}
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
            <CardContent class="pl-4 font-light">
                <List>
                    <ListItem class="p-0 m-0 flex-row">
                        <Typography variant="body2" color="text.secondary" class="text-pretty font-light">
                            Price: ${item.price}
                        </Typography>
                    </ListItem>
                    <ListItem class="p-0 m-0 flex-row">
                        <Typography variant="body2" color="text.secondary" class="text-pretty font-light">
                            Type: {item.type}
                        </Typography>
                    </ListItem>
                </List>
            </CardContent>
            <CardActions disableSpacing class="">
                <IconButton aria-label="add to favorites" color='error'>
                    <Favorite />
                </IconButton>
                <IconButton aria-label="share" color='info'>
                    <Share />
                </IconButton>
            </CardActions>
        </Card>
    )
}