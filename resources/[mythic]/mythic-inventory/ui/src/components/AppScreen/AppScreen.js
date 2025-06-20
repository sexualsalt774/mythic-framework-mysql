import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { IconButton } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { closeInventory } from '../Inventory/actions';
import Nui from '../../util/Nui';

const useStyles = makeStyles((theme) => ({
	outsideDiv: {
		width: "100vw",
		height: "100vh",
		display: "flex",
		justifyContent: "center",
		alignItems: "center",
		zIndex: -1,
		background: "rgba(0,0,0,0.6)",
		//backdropFilter: "blur(3px)",
		"@global": {
		  "*::-webkit-scrollbar": {
			width: 6,
		  },
		  "*::-webkit-scrollbar-thumb": {
			background: "rgba(255, 255, 255, 0.1)",
			borderRadius: 3,
			transition: "background ease-in 0.15s",
		  },
		  "*::-webkit-scrollbar-thumb:hover": {
			background: "rgba(255, 255, 255, 0.2)",
		  },
		  "*::-webkit-scrollbar-track": {
			background: "transparent",
		  },
		},
		userSelect: "none",
		"-webkit-user-select": "none",
	  },
	  insideDiv: {
		width: "100%",
		height: "100%",
		userSelect: "none",
		"-webkit-user-select": "none",
	  },
	  dialog: {
		display: "flex",
		flexDirection: "column",
		margin: "auto",
		width: "fit-content",
		zIndex: -1,
	  },
	  closeButton: {
		position: "absolute",
		top: 20,
		left: 20,
		color: theme.palette.text.main,
		background: "rgba(18, 18, 28, 0.8)",
		width: 40,
		height: 40,
		minWidth: 40,
		borderRadius: 8,
		boxShadow: "0 4px 10px rgba(0, 0, 0, 0.2)",
		border: "1px solid rgba(255, 255, 255, 0.05)",
		transition: "all 0.2s ease",
		"&:hover": {
		  background: "rgba(28, 28, 38, 0.8)",
		  color: theme.palette.primary.main,
		  transform: "translateY(-2px)",
		  boxShadow: "0 6px 15px rgba(0, 0, 0, 0.3)",
		  "& svg": {
			transition: "transform ease-in 0.15s",
			transform: "rotate(90deg)",
		  },
		},
	  },
}));

export default (props) => {
	const classes = useStyles();
	const dispatch = useDispatch();
	const itemsLoaded = useSelector((state) => state.inventory.itemsLoaded);
	const hoverOrigin = useSelector((state) => state.inventory.hoverOrigin);

	const onClick = () => {
		if (Boolean(hoverOrigin)) {
			Nui.send('FrontEndSound', 'DISABLED');
			dispatch({
				type: 'SET_HOVER',
				payload: null,
			});
			dispatch({
				type: 'SET_HOVER_ORIGIN',
				payload: null,
			});
		}
	};

	const close = () => {
		dispatch({
			type: 'SET_CONTEXT_ITEM',
			payload: null,
		});
		dispatch({
			type: 'SET_SPLIT_ITEM',
			payload: null,
		});
		closeInventory();
	};
	
	return (
		<>
			{!props.hidden && itemsLoaded && (
				<div className={classes.outsideDiv} onClick={onClick}>
					<IconButton
						className={classes.closeButton}
						variant="contained"
						color="primary"
						onClick={close}
					>
						<FontAwesomeIcon icon={['fas', 'x']} />
					</IconButton>
					<div className={classes.insideDiv}>{props.children}</div>
				</div>
			)}
		</>
	);
};
