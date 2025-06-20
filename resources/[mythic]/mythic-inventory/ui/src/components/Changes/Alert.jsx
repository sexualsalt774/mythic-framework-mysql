import React, { Fragment, useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { makeStyles } from '@mui/styles';
import { Fade } from '@mui/material';
import { getItemImage, getItemLabel } from '../Inventory/item';

const useStyles = makeStyles((theme) => ({
	container: {
		pointerEvents: "none",
		zIndex: 1,
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
		height: 30,
		lineHeight: "30px",
		fontSize: 13,
		fontWeight: 500,
		width: "100%",
		maxWidth: "100%",
		overflow: "hidden",
		whiteSpace: "nowrap",
		color: "white",
		background: "rgba(0, 0, 0, 0.7)",
		//backdropFilter: "blur(5px)",
		borderTop: "1px solid rgba(255, 255, 255, 0.05)",
		zIndex: 4,
	  },
	  slot: {
		width: 125,
		height: 125,
		background: "rgba(18, 18, 28, 0.7)",
		border: `1px solid rgba(255, 255, 255, 0.05)`,
		position: "relative",
		zIndex: 2,
		borderRadius: 8,
		//backdropFilter: "blur(5px)",
		boxShadow: "0 4px 15px rgba(0, 0, 0, 0.15)",
		overflow: "hidden",
		"&.add": {
		  borderBottom: `2px solid ${theme.palette.success.main}`,
		},
		"&.removed": {
		  borderBottom: `2px solid ${theme.palette.error.main}`,
		},
		"&.used": {
		  borderBottom: `2px solid ${theme.palette.info.main}`,
		},
	  },
	  count: {
		top: 8,
		right: 8,
		position: "absolute",
		textAlign: "right",
		padding: "2px 6px",
		color: theme.palette.text.main,
		background: "rgba(0, 0, 0, 0.7)",
		borderRadius: 4,
		fontSize: 12,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
	  },
	  type: {
		top: 8,
		left: 8,
		position: "absolute",
		padding: "2px 6px",
		color: theme.palette.text.main,
		background: "rgba(0, 0, 0, 0.7)",
		borderRadius: 4,
		fontSize: 11,
		fontWeight: 600,
		zIndex: 4,
		boxShadow: "0 2px 4px rgba(0, 0, 0, 0.2)",
	  },
}));

export default ({ alert }) => {
	const classes = useStyles();
	const dispatch = useDispatch();
	const itemData = useSelector((state) => state.inventory.items)[alert.item];

	const [show, setShow] = useState(true);

	useEffect(() => {
		let t = setTimeout(() => {
			setShow(false);
		}, 3000);

		return () => {
			clearTimeout(t);
		};
	}, []);

	const onAnimEnd = () => {
		dispatch({
			type: 'DISMISS_ALERT',
			payload: {
				id: alert.id,
			},
		});
	};

	const getTypeLabel = () => {
		switch (alert.type) {
			case 'add':
				return 'Added';
			case 'removed':
				return 'Removed';
			case 'used':
				return 'Used';
			default:
				return alert.type;
		}
	};

	return (
		<Fade in={show} onExited={onAnimEnd}>
			<div className={classes.container}>
				<div className={`${classes.slot} ${alert.type}`}>
					<div
						className={classes.img}
						style={{
							backgroundImage: `url(${getItemImage(
								alert.item,
								itemData,
							)})`,
						}}
					></div>
					{Boolean(itemData) && (
						<div className={classes.label}>
							{getItemLabel(alert.item, itemData)}
						</div>
					)}
					<div className={classes.type}>{getTypeLabel()}</div>
					{alert.count > 0 && (
						<div className={classes.count}>{alert.count}</div>
					)}
				</div>
			</div>
		</Fade>
	);
};
