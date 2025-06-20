import React, { Fragment, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { LinearProgress } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { getItemImage, getItemLabel } from './item';

const initialState = {
	mouseX: null,
	mouseY: null,
};
const useStyles = makeStyles((theme) => ({
	hover: {
		position: "absolute",
		top: 0,
		left: 0,
		pointerEvents: "none",
		zIndex: 1000,
		filter: "drop-shadow(0 10px 20px rgba(0, 0, 0, 0.4))",
	  },
	  img: {
		height: 125,
		width: "100%",
		overflow: "hidden",
		zIndex: 3,
		backgroundSize: "55%",
		backgroundRepeat: "no-repeat",
		backgroundPosition: "center center",
		display: "flex",
		alignItems: "center",
		justifyContent: "center",
	  },
	  label: {
		bottom: 0,
		left: 0,
		position: "absolute",
		textAlign: "center",
		padding: "0 5px",
		width: "100%",
		maxWidth: "100%",
		overflow: "hidden",
		whiteSpace: "nowrap",
		color: theme.palette.text.main,
		background: "rgba(13, 22, 37, 0.9)",
		//backdropFilter: "blur(5px)",
		borderTop: `1px solid rgba(255, 255, 255, 0.05)`,
		borderBottomLeftRadius: 12,
		borderBottomRightRadius: 12,
		height: 30,
		lineHeight: "30px",
		fontSize: 13,
		fontWeight: 500,
		zIndex: 4,
	  },
	  slot: {
		width: 125,
		height: 125,
		background: "rgba(19, 28, 46, 0.85)",
		//backdropFilter: "blur(5px)",
		border: `1px solid rgba(255, 255, 255, 0.1)`,
		position: "relative",
		zIndex: 2,
		borderRadius: 12,
		boxShadow: "0 10px 30px rgba(0, 0, 0, 0.3)",
		overflow: "hidden",
		"&.rarity-1": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare1}`,
		},
		"&.rarity-2": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare2}`,
		},
		"&.rarity-3": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare3}`,
		},
		"&.rarity-4": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare4}`,
		},
		"&.rarity-5": {
		  borderBottom: `2px solid ${theme.palette.rarities.rare5}`,
		},
	  },
	  count: {
		top: 8,
		right: 8,
		position: "absolute",
		textAlign: "right",
		padding: "2px 6px",
		color: theme.palette.text.main,
		background: "rgba(13, 22, 37, 0.85)",
		borderRadius: 4,
		fontSize: 12,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
	  },
	  price: {
		top: 8,
		left: 8,
		position: "absolute",
		padding: "2px 6px",
		color: theme.palette.success.main,
		background: "rgba(13, 22, 37, 0.85)",
		borderRadius: 4,
		fontSize: 11,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
		"&::before": {
		  content: '"$"',
		  marginRight: 2,
		  color: theme.palette.text.main,
		},
	  },
	  durability: {
		bottom: 30,
		left: 0,
		position: "absolute",
		width: "100%",
		maxWidth: "100%",
		overflow: "hidden",
		height: 3,
		background: "transparent",
		zIndex: 4,
		"&.broken": {
		  background: theme.palette.text.alt,
		},
	  },
	  broken: {
		background: theme.palette.text.alt,
		transition: "none !important",
	  },
	  progressbar: {
		transition: "none !important",
		height: 3,
	  },
}));

export default (props) => {
	const classes = useStyles();
	const hover = useSelector((state) => state.inventory.hover);
	const itemData = useSelector((state) => state.inventory.items)[hover?.Name];
	const [state, setState] = React.useState(initialState);

	const calcDurability = () => {
		if (!Boolean(hover) || !Boolean(itemData?.durability)) null;
		return Math.ceil(
			100 -
				((Math.floor(Date.now() / 1000) - hover?.CreateDate) /
					itemData?.durability) *
					100,
		);
	};
	const durability = calcDurability();

	const mouseMove = (event) => {
		event.preventDefault();
		setState({
			mouseX: event.clientX,
			mouseY: event.clientY,
		});
	};

	useEffect(() => {
		document.addEventListener('mousemove', mouseMove);
		return () => document.removeEventListener('mousemove', mouseMove);
	}, []);

	if (hover) {
		return (
			<div
				className={classes.hover}
				style={
					state.mouseY !== null && state.mouseX !== null
						? {
								top: state.mouseY,
								left: state.mouseX,
								transform: 'translate(-50%, -50%)',
						  }
						: undefined
				}
			>
				<div className={`${classes.slot} rarity-${itemData.rarity}`}>
					{Boolean(hover) && (
						<div
							className={classes.img}
							style={{
								backgroundImage: `url(${getItemImage(
									hover,
									itemData,
								)})`,
							}}
						></div>
					)}
					{Boolean(itemData) && (
						<div className={classes.label}>
							{getItemLabel(hover, itemData)}
						</div>
					)}
					{Boolean(hover) && hover.Count > 0 && (
						<div className={classes.count}>{hover.Count}</div>
					)}
					{Boolean(itemData?.durability) &&
						Boolean(hover?.CreateDate) &&
						(durability > 0 ? (
							<LinearProgress
								className={classes.durability}
								color={
									durability >= 75
										? 'success'
										: durability >= 50
										? 'warning'
										: 'error'
								}
								classes={{
									determinate: classes.progressbar,
									bar: classes.progressbar,
									bar1: classes.progressbar,
								}}
								variant="determinate"
								value={durability}
							/>
						) : (
							<LinearProgress
								className={classes.durability}
								classes={{
									determinate: classes.broken,
									bar: classes.broken,
									bar1: classes.broken,
								}}
								color="secondary"
								variant="determinate"
								value={100}
							/>
						))}
					{hover.shop && Boolean(itemData) && (
						<div className={classes.price}>
							{hover.free ? 'FREE' : itemData.price * hover.Count}
						</div>
					)}
				</div>
			</div>
		);
	} else {
		return <Fragment />;
	}
};